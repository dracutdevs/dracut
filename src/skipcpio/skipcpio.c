/* skipcpio.c

   Copyright (C) 2012 Harald Hoyer
   Copyright (C) 2012 Red Hat, Inc.  All rights reserved.

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

#define PROGRAM_VERSION_STRING "1"

#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define CPIO_MAGIC "070701"
#define CPIO_MAGIC_LEN (sizeof(CPIO_MAGIC) - 1)

#define CPIO_END "TRAILER!!!"
#define CPIO_ENDLEN (sizeof(CPIO_END) - 1)

#define CPIO_ALIGNMENT 4

#define ALIGN_UP(n, a) (((n) + (a) - 1) & (~((a) - 1)))

#define pr_err(fmt, ...) \
        fprintf(stderr, "ERROR: %s:%d:%s(): " fmt, __FILE__, __LINE__, \
                __func__, ##__VA_ARGS__)

struct cpio_header {
        char c_magic[CPIO_MAGIC_LEN];
        char c_ino[8];
        char c_mode[8];
        char c_uid[8];
        char c_gid[8];
        char c_nlink[8];
        char c_mtime[8];
        char c_filesize[8];
        char c_dev_maj[8];
        char c_dev_min[8];
        char c_rdev_maj[8];
        char c_rdev_min[8];
        char c_namesize[8];
        char c_chksum[8];
} __attribute__((packed));

struct buf_struct {
        struct cpio_header h;
        char filename[CPIO_ENDLEN];
} __attribute__((packed));

union buf_union {
        struct buf_struct cpio;
        char copy_buffer[2048];
};

static union buf_union buf;

int main(int argc, char **argv)
{
        size_t s;
        long pos = 0;
        FILE *f = NULL;
        char *fname = NULL;
        int ret = EXIT_FAILURE;
        unsigned long filesize;
        unsigned long filename_length;

        if (argc != 2) {
                fprintf(stderr, "Usage: %s <file>\n", argv[0]);
                goto end;
        }

        fname = argv[1];
        f = fopen(fname, "r");
        if (f == NULL) {
                pr_err("Cannot open file '%s'\n", fname);
                goto end;
        }

        if ((fread(&buf.cpio, sizeof(buf.cpio), 1, f) != 1) ||
            ferror(f)) {
                pr_err("Read error from file '%s'\n", fname);
                goto end;
        }

        if (fseek(f, 0, SEEK_SET)) {
                pr_err("fseek error on file '%s'\n", fname);
                goto end;
        }

        /* check, if this is a cpio archive */
        if (memcmp(buf.cpio.h.c_magic, CPIO_MAGIC, CPIO_MAGIC_LEN)) {
                goto cat_rest;
        }

        do {
                // zero string, spilling into next unused field, to use strtol
                buf.cpio.h.c_chksum[0] = 0;
                filename_length = strtoul(buf.cpio.h.c_namesize, NULL, 16);
                pos = ALIGN_UP(pos + sizeof(struct cpio_header) + filename_length, CPIO_ALIGNMENT);

                // zero string, spilling into next unused field, to use strtol
                buf.cpio.h.c_dev_maj[0] = 0;
                filesize = strtoul(buf.cpio.h.c_filesize, NULL, 16);
                pos = ALIGN_UP(pos + filesize, CPIO_ALIGNMENT);

                if (filename_length == (CPIO_ENDLEN + 1)
                    && strncmp(buf.cpio.filename, CPIO_END, CPIO_ENDLEN) == 0) {
                        if (fseek(f, pos, SEEK_SET)) {
                                pr_err("fseek\n");
                                goto end;
                        }
                        break;
                }

                if (fseek(f, pos, SEEK_SET)) {
                        pr_err("fseek\n");
                        goto end;
                }

                if ((fread(&buf.cpio, sizeof(buf.cpio), 1, f) != 1) ||
                    ferror(f)) {
                        pr_err("fread\n");
                        goto end;
                }

                if (memcmp(buf.cpio.h.c_magic, CPIO_MAGIC, CPIO_MAGIC_LEN)) {
                        pr_err("Corrupt CPIO archive!\n");
                        goto end;
                }
        } while (!feof(f));

        if (feof(f)) {
                /* CPIO_END not found, just cat the whole file */
                if (fseek(f, 0, SEEK_SET)) {
                        pr_err("fseek\n");
                        goto end;
                }
        } else {
                /* skip zeros */
                do {
                        size_t i;

                        s = fread(buf.copy_buffer, 1, sizeof(buf.copy_buffer) - 1, f);
                        if (ferror(f)) {
                                pr_err("fread\n");
                                goto end;
                        }

                        for (i = 0; (i < s) && (buf.copy_buffer[i] == 0); i++) ;

                        if (buf.copy_buffer[i]) {
                                pos += i;

                                if (fseek(f, pos, SEEK_SET)) {
                                        pr_err("fseek\n");
                                        goto end;
                                }
                                break;
                        }

                        pos += s;
                } while (!feof(f));
        }

cat_rest:
        /* cat out the rest */
        while (!feof(f)) {
                s = fread(buf.copy_buffer, 1, sizeof(buf.copy_buffer), f);
                if (ferror(f)) {
                        pr_err("fread\n");
                        goto end;
                }

                errno = 0;
                if (fwrite(buf.copy_buffer, 1, s, stdout) != s) {
                        if (errno != EPIPE)
                                pr_err("fwrite\n");
                        goto end;
                }
        }

        ret = EXIT_SUCCESS;

end:
        if (f) {
                fclose(f);
        }

        return ret;
}
