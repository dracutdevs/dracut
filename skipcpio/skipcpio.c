/* dracut-install.c  -- install files and executables

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

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define CPIO_MAGIC "070701"
#define CPIO_END "TRAILER!!!"
#define CPIO_ENDLEN (sizeof(CPIO_END) - 1)

#define CPIO_ALIGNMENT 4

struct cpio_header {
        char c_magic[6];
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

#define ALIGN_UP(n, a) (((n) + (a) - 1) & (~((a) - 1)))

int main(int argc, char **argv)
{
        FILE *f;
        size_t s;

        if (argc != 2) {
                fprintf(stderr, "Usage: %s <file>\n", argv[0]);
                exit(1);
        }

        f = fopen(argv[1], "r");

        if (f == NULL) {
                fprintf(stderr, "Cannot open file '%s'\n", argv[1]);
                exit(1);
        }

        s = fread(&buf.cpio, sizeof(buf.cpio), 1, f);
        if (s <= 0) {
                fprintf(stderr, "Read error from file '%s'\n", argv[1]);
                fclose(f);
                exit(1);
        }
        fseek(f, 0, SEEK_SET);

        /* check, if this is a cpio archive */
        if (memcmp(buf.cpio.h.c_magic, CPIO_MAGIC, 6) == 0) {

                long pos = 0;

                unsigned long filesize;
                unsigned long filename_length;

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
                                fseek(f, pos, SEEK_SET);
                                break;
                        }

                        if (fseek(f, pos, SEEK_SET) != 0) {
                                perror("fseek");
                                exit(1);
                        }

                        if (fread(&buf.cpio, sizeof(buf.cpio), 1, f) != 1) {
                                perror("fread");
                                exit(1);
                        }

                        if (memcmp(buf.cpio.h.c_magic, CPIO_MAGIC, 6) != 0) {
                                fprintf(stderr, "Corrupt CPIO archive!\n");
                                exit(1);
                        }
                } while (!feof(f));

                if (feof(f)) {
                        /* CPIO_END not found, just cat the whole file */
                        fseek(f, 0, SEEK_SET);
                } else {
                        /* skip zeros */
                        do {
                                size_t i;

                                s = fread(buf.copy_buffer, 1, sizeof(buf.copy_buffer) - 1, f);
                                if (s <= 0)
                                        break;

                                for (i = 0; (i < s) && (buf.copy_buffer[i] == 0); i++) ;

                                if (buf.copy_buffer[i] != 0) {
                                        pos += i;

                                        fseek(f, pos, SEEK_SET);
                                        break;
                                }

                                pos += s;
                        } while (!feof(f));
                }
        }
        /* cat out the rest */
        while (!feof(f)) {
                s = fread(buf.copy_buffer, 1, sizeof(buf.copy_buffer), f);
                if (s <= 0)
                        break;

                s = fwrite(buf.copy_buffer, 1, s, stdout);
                if (s <= 0)
                        break;
        }
        fclose(f);

        return EXIT_SUCCESS;
}
