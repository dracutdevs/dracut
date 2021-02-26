/*
   Copyright (C) 2021 SUSE LLC

   This program is free software: you can redistribute it and/or modify
   under the terms of the GNU Lesser General Public License as published by
   the Free Software Foundation; either version 2.1 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public License
   along with this program; If not, see <http://www.gnu.org/licenses/>.
*/

#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

#define _LARGEFILE64_SOURCE
#include <sys/stat.h>
#include <sys/types.h>
#include <linux/limits.h>
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <getopt.h>
#include "skipcpio.h"

#ifdef DEBUG
/* make CFLAGS="-DDEBUG" */
#define dout(...) fprintf(stderr, __VA_ARGS__)
#else
#define dout(...)
#endif

static void usage(int status)
{
        fprintf(stdout,
                "Usage: padcpio -a ALIGNMENT [-d PADDIR] [-m SIZE] [-o OFFSET]\n\n"
                "  -a --align     Pad input file data to ALIGNMENT (required)\n"
                "  -d --paddir    Create PADDIR for padding files  (default=pad)\n"
                "  -m --min       Don't pad for files under SIZE   (default=1)\n"
                "  -o --offset    Calculate padding from OFFSET    (default=0)\n"
                "  -h --help      Show this help\n\n"
                "Example:\n"
                "  echo \"This data will be 4K aligned within out.cpio\" > file\n"
                "  printf \"file\\0\" | padcpio -a 4k | cpio -o --null -H newc -O out.cpio\n\n");

        exit(status);
}

static int unit_multiply(const char *unit, unsigned long *_val)
{
        unsigned long val = *_val;

        switch (unit[0]) {
        case 'T':
        case 't':
                val *= 1024;    /* fall through */
        case 'G':
        case 'g':
                val *= 1024;    /* fall through */
        case 'M':
        case 'm':
                val *= 1024;    /* fall through */
        case 'K':
        case 'k':
                val *= 1024;
                if (unit[1] != '\0')
                        return -1;
        /* fall through */
        case '\0':
                break;
        default:
                return -1;
        }
        if (val < *_val)
                return -1;      /* overflow */

        *_val = val;
        return 0;
}

const char *skip_relative_dot_slash(const char *path)
{
        const char *p = path;
        if (p[0] == '/') {
                fprintf(stderr, "error: %s is an absolute path\n", path);
                return NULL;
        }
        while (p[0] == '.' && p[1] == '/') {
                p++;
                while (p[0] == '/')
                        p++;
        }
        if (p[0] == '\0') {
                fprintf(stderr, "error: %s is invalid\n", path);
                return NULL;
        }
        return p;
}

static void parse_args(int argc, char *argv[],
                       unsigned long *_pad_align,
                       const char **_pad_dir, unsigned long *_min_file_size, off_t *_archive_off)
{
        unsigned long pad_align = 0;
        const char *pad_dir = "pad";
        unsigned long min_file_size = 1;
        unsigned long archive_off = 0;
        int c;
        int sret;
        struct stat sb;
        static struct option const options[] = {
                {"alignment", required_argument, NULL, 'a'},
                {"paddir", required_argument, NULL, 'd'},
                {"min", required_argument, NULL, 'm'},
                {"offset", required_argument, NULL, 'o'},
                {"help", no_argument, NULL, 'h'},
                {NULL, 0, NULL, 0}
        };

        while ((c = getopt_long(argc, argv, "a:d:m:h", options, NULL)) != -1) {
                char *eptr;
                switch (c) {
                case 'a':
                        eptr = NULL;
                        pad_align = strtoul(optarg, &eptr, 10);
                        if (eptr == optarg || unit_multiply(eptr, &pad_align) < 0) {
                                fprintf(stderr, "invalid alignment value \'%s\'\n", optarg);
                                usage(EXIT_FAILURE);
                        }
                        break;
                case 'd':
                        pad_dir = skip_relative_dot_slash(optarg);
                        if (pad_dir == NULL) {
                                usage(EXIT_FAILURE);
                        }
                        /* no support for nested pad paths or trailing slashes */
                        if (strchr(pad_dir, '/') != NULL) {
                                fprintf(stderr, "paddir \'%s\' invalid: " "nested path or trailing slashes\n", pad_dir);
                                usage(EXIT_FAILURE);
                        }
                        break;
                case 'm':
                        eptr = NULL;
                        min_file_size = strtoul(optarg, &eptr, 10);
                        if (eptr == optarg || unit_multiply(eptr, &min_file_size) < 0) {
                                fprintf(stderr, "invalid minimum size \'%s\'\n", optarg);
                                usage(EXIT_FAILURE);
                        }
                        break;
                case 'o':
                        eptr = NULL;
                        archive_off = strtoul(optarg, &eptr, 10);
                        if (eptr == optarg || unit_multiply(eptr, &min_file_size) < 0) {
                                fprintf(stderr, "invalid offset \'%s\'\n", optarg);
                                usage(EXIT_FAILURE);
                        }
                        break;
                case 'h':
                        usage(EXIT_SUCCESS);
                        break;
                default:
                        usage(EXIT_FAILURE);
                }
        }

        if (optind == 1 || optind != argc) {
                usage(EXIT_FAILURE);
        }

        if (pad_align == 0 || (pad_align & (pad_align - 1)) != 0) {
                fprintf(stderr, "invalid alignment \'%lu\': must be a power of two\n", pad_align);
                usage(EXIT_FAILURE);
        }

        sret = stat(pad_dir, &sb);
        if (sret == 0 || errno != ENOENT) {
                fprintf(stderr, "error: paddir \'%s\' path must not exist\n", pad_dir);
                exit(1);
        }

        *_pad_align = pad_align;
        *_pad_dir = pad_dir;
        *_min_file_size = min_file_size;
        *_archive_off = archive_off;
}

int pad_file_prepend(const char *pad_dirname, int pad_num, const char *in_path,
                     size_t in_data_len, unsigned long pad_align, off_t *archive_off)
{
        char pad_path[PATH_MAX];
        int ret;
        int fd;
        off_t real_data_off;
        off_t aligned_data_off;
        off_t next_off;
        off_t pad_data_len;

        ret = snprintf(pad_path, sizeof(pad_path), "%s/%d", pad_dirname, pad_num);
        if (ret >= sizeof(pad_path))
                return -E2BIG;

        fd = open(pad_path, O_CREAT | O_EXCL | O_WRONLY, 0600);
        if (fd < 0) {
                fprintf(stderr, "failed to create padding at %s: %s\n", pad_path, strerror(errno));
                return -errno;
        }

        real_data_off = ALIGN_UP(*archive_off + sizeof(struct cpio_header) + strlen(pad_path) + 1, CPIO_ALIGNMENT)
                        /* pad data will go here */
                        + ALIGN_UP(sizeof(struct cpio_header) + strlen(in_path) + 1, CPIO_ALIGNMENT);

        aligned_data_off = ALIGN_UP(real_data_off, pad_align);
        pad_data_len = aligned_data_off - real_data_off;

        /* take into account size of header and pad_path for next entry */
        ret = ftruncate(fd, pad_data_len);
        if (ret < 0) {
                fprintf(stderr, "failed to truncate %s to %lu: %s\n", pad_path, pad_data_len, strerror(errno));
                ret = -errno;
                close(fd);
                return ret;
        }
        ret = close(fd);
        if (ret < 0)
                return -errno;

        dout("pad file %s size %lu inserted before %s size %lu\n", pad_path, pad_data_len, in_path, in_data_len);

        fprintf(stdout, "%s%c", pad_path, '\0');
        next_off = ALIGN_UP(*archive_off + sizeof(struct cpio_header) + strlen(pad_path) + 1, CPIO_ALIGNMENT)
                   + ALIGN_UP(pad_data_len, CPIO_ALIGNMENT);
        dout("%s: archive offset: [%lu, %lu)\n", pad_path, *archive_off, next_off);
        *archive_off = next_off;

        fprintf(stdout, "%s%c", in_path, '\0');
        next_off = ALIGN_UP(*archive_off + sizeof(struct cpio_header) + strlen(in_path) + 1, CPIO_ALIGNMENT)
                   + ALIGN_UP(in_data_len, CPIO_ALIGNMENT);
        dout("%s: archive offset: [%lu, %lu)\n", in_path, *archive_off, next_off);
        *archive_off = next_off;

        return 0;
}

char *hardlink_names = NULL;
size_t hardlink_names_size = 0;
off_t hardlink_names_off = 0;

int main(int argc, char **argv)
{
        unsigned long pad_align = 0;
        const char *pad_dirname = NULL;
        unsigned long min_file_size = 1;
        int pad_num = 0;
        int sret;
        struct stat sb;
        char *line = NULL;
        size_t len = 0;
        ssize_t nread;
        int ret = EXIT_FAILURE;
        off_t archive_off = 0;

        parse_args(argc, argv, &pad_align, &pad_dirname, &min_file_size, &archive_off);

        while ((nread = getdelim(&line, &len, '\0', stdin)) != -1) {
                off_t this_doff;
                const char *in_path;

                if (nread >= PATH_MAX) {
                        fprintf(stderr, "input path too large\n");
                        goto err_line_free;
                }

                in_path = skip_relative_dot_slash(line);
                if (in_path == NULL) {
                        goto err_line_free;
                }

                sret = lstat(in_path, &sb);
                if (sret < 0) {
                        fprintf(stderr, "stat failed for %s\n", line);
                        goto err_line_free;
                }

                this_doff = ALIGN_UP(archive_off + sizeof(struct cpio_header)
                                     + strlen(in_path) + 1, CPIO_ALIGNMENT);

                if (S_ISLNK(sb.st_mode)) {
                        ssize_t bytes;
                        char lnk_tgt[PATH_MAX];
                        bytes = readlink(in_path, lnk_tgt, sizeof(lnk_tgt));
                        if (bytes <= 0 || bytes >= sizeof(lnk_tgt)) {
                                fprintf(stderr, "readlink failed for %s\n", line);
                                goto err_line_free;
                        }
                        fprintf(stdout, "%s%c", in_path, '\0');
                        dout("%s: archive offset: [%lu, %lu)\n", in_path, archive_off,
                             ALIGN_UP(this_doff + bytes, CPIO_ALIGNMENT));
                        archive_off = ALIGN_UP(this_doff + bytes, CPIO_ALIGNMENT);
                        continue;
                }

                if (!S_ISREG(sb.st_mode)) {
                        /* non-file or size under minimum for padding */
                        fprintf(stdout, "%s%c", in_path, '\0');
                        dout("%s: archive offset: [%lu, %lu)\n", in_path, archive_off, this_doff);
                        archive_off = this_doff;
                        continue;
                }

                if (sb.st_nlink > 1) {
                        /*
                         * GNU cpio deferrs hardlink processing until last link.
                         * Avoid the complexity of determining when they appear
                         * by just deferring them all to the end of the archive
                         * without any padding.
                         */
                        size_t len = strlen(in_path) + 1;
                        if (hardlink_names_off + len > hardlink_names_size) {
                                char *hardlink_names_n = realloc(hardlink_names, hardlink_names_off + len);
                                if (hardlink_names_n == NULL)
                                        goto err_line_free;
                                hardlink_names = hardlink_names_n;
                                hardlink_names_size = hardlink_names_off + len;
                        }
                        memcpy(&hardlink_names[hardlink_names_off], in_path, len);
                        hardlink_names_off += len;
                        dout("%s: hardlink deferred to end\n", in_path);
                        continue;
                }

                if (sb.st_size < min_file_size || this_doff == ALIGN_UP(this_doff, pad_align)) {
                        /* data segment under min-size for padding or already aligned */
                        fprintf(stdout, "%s%c", in_path, '\0');
                        dout("%s: archive offset: [%lu, %lu)\n", in_path, archive_off,
                             ALIGN_UP(this_doff + sb.st_size, CPIO_ALIGNMENT));
                        archive_off = ALIGN_UP(this_doff + sb.st_size, CPIO_ALIGNMENT);
                        continue;
                }

                if (pad_num == 0) {
                        ret = mkdir(pad_dirname, 0700);
                        if (ret < 0) {
                                fprintf(stderr, "Cannot create '%s'\n", pad_dirname);
                                goto err_line_free;
                        }

                        fprintf(stdout, "%s%c", pad_dirname, '\0');
                        dout("%s: archive offset: [%lu, %lu)\n", pad_dirname, archive_off,
                             ALIGN_UP(archive_off + sizeof(struct cpio_header) + strlen(pad_dirname) + 1,
                                      CPIO_ALIGNMENT));
                        archive_off = ALIGN_UP(archive_off + sizeof(struct cpio_header)
                                               + strlen(pad_dirname) + 1, CPIO_ALIGNMENT);
                }
                ret = pad_file_prepend(pad_dirname, pad_num, in_path, sb.st_size, pad_align, &archive_off);
                if (ret < 0) {
                        fprintf(stderr, "Cannot create '%s'\n", pad_dirname);
                        goto err_line_free;
                }
                pad_num++;
        }

        if (hardlink_names_off != 0 && fwrite(hardlink_names, hardlink_names_off, 1, stdout) != 1)
                goto err_line_free;
        free(line);
        free(hardlink_names);
        return EXIT_SUCCESS;
err_line_free:
        free(line);
        free(hardlink_names);
        return EXIT_FAILURE;
}
