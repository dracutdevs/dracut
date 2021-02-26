/*
   Copyright (C) 2021 Harald Hoyer
   Copyright (C) 2021 Red Hat, Inc.  All rights reserved.

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

#define ALIGN_UP(n, a) (((n) + (a) - 1) & (~((a) - 1)))
