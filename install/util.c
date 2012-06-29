/*-*- Mode: C; c-basic-offset: 8; indent-tabs-mode: nil -*-*/

/***
  This file is part of systemd.

  Copyright 2010 Lennart Poettering

  systemd is free software; you can redistribute it and/or modify it
  under the terms of the GNU Lesser General Public License as published by
  the Free Software Foundation; either version 2.1 of the License, or
  (at your option) any later version.

  systemd is distributed in the hope that it will be useful, but
  WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
  Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General Public License
  along with systemd; If not, see <http://www.gnu.org/licenses/>.
***/

#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/syscall.h>

#include "util.h"

static inline pid_t gettid(void) {
        return (pid_t) syscall(SYS_gettid);
}

size_t page_size(void) {
        static __thread size_t pgsz = 0;
        long r;

        if (_likely_(pgsz > 0))
                return pgsz;

        assert_se((r = sysconf(_SC_PAGESIZE)) > 0);

        pgsz = (size_t) r;

        return pgsz;
}

bool endswith(const char *s, const char *postfix) {
        size_t sl, pl;

        assert(s);
        assert(postfix);

        sl = strlen(s);
        pl = strlen(postfix);

        if (pl == 0)
                return true;

        if (sl < pl)
                return false;

        return memcmp(s + sl - pl, postfix, pl) == 0;
}
int close_nointr(int fd) {
        assert(fd >= 0);

        for (;;) {
                int r;

                r = close(fd);
                if (r >= 0)
                        return r;

                if (errno != EINTR)
                        return -errno;
        }
}

void close_nointr_nofail(int fd) {
        int saved_errno = errno;

        /* like close_nointr() but cannot fail, and guarantees errno
         * is unchanged */

        assert_se(close_nointr(fd) == 0);

        errno = saved_errno;
}

int open_terminal(const char *name, int mode) {
        int fd, r;
        unsigned c = 0;

        /*
         * If a TTY is in the process of being closed opening it might
         * cause EIO. This is horribly awful, but unlikely to be
         * changed in the kernel. Hence we work around this problem by
         * retrying a couple of times.
         *
         * https://bugs.launchpad.net/ubuntu/+source/linux/+bug/554172/comments/245
         */

        for (;;) {
                if ((fd = open(name, mode)) >= 0)
                        break;

                if (errno != EIO)
                        return -errno;

                if (c >= 20)
                        return -errno;

                usleep(50 * USEC_PER_MSEC);
                c++;
        }

        if (fd < 0)
                return -errno;

        if ((r = isatty(fd)) < 0) {
                close_nointr_nofail(fd);
                return -errno;
        }

        if (!r) {
                close_nointr_nofail(fd);
                return -ENOTTY;
        }

        return fd;
}

bool streq_ptr(const char *a, const char *b) {

        /* Like streq(), but tries to make sense of NULL pointers */

        if (a && b)
                return streq(a, b);

        if (!a && !b)
                return true;

        return false;
}
bool is_main_thread(void) {
        static __thread int cached = 0;

        if (_unlikely_(cached == 0))
                cached = getpid() == gettid() ? 1 : -1;

        return cached > 0;
}

int safe_atou(const char *s, unsigned *ret_u) {
        char *x = NULL;
        unsigned long l;

        assert(s);
        assert(ret_u);

        errno = 0;
        l = strtoul(s, &x, 0);

        if (!x || *x || errno)
                return errno ? -errno : -EINVAL;

        if ((unsigned long) (unsigned) l != l)
                return -ERANGE;

        *ret_u = (unsigned) l;
        return 0;
}

static const char *const log_level_table[] = {
        [LOG_EMERG] = "emerg",
        [LOG_ALERT] = "alert",
        [LOG_CRIT] = "crit",
        [LOG_ERR] = "err",
        [LOG_WARNING] = "warning",
        [LOG_NOTICE] = "notice",
        [LOG_INFO] = "info",
        [LOG_DEBUG] = "debug"
};

DEFINE_STRING_TABLE_LOOKUP(log_level, int);
