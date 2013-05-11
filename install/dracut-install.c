/*-*- Mode: C; c-basic-offset: 8; indent-tabs-mode: nil -*-*/

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

#include <ctype.h>
#include <errno.h>
#include <fcntl.h>
#include <getopt.h>
#include <libgen.h>
#include <limits.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
#include <sys/ioctl.h>

#include "log.h"
#include "hashmap.h"
#include "util.h"

static bool arg_hmac = false;
static bool arg_createdir = false;
static int arg_loglevel = -1;
static bool arg_optional = false;
static bool arg_all = false;
static bool arg_resolvelazy = false;
static bool arg_resolvedeps = false;
static char *destrootdir = NULL;

static Hashmap *items = NULL;
static Hashmap *items_failed = NULL;

static int dracut_install(const char *src, const char *dst, bool isdir, bool resolvedeps, bool hashdst);

static size_t dir_len(char const *file)
{
        size_t length;

        if(!file)
                return 0;

        /* Strip the basename and any redundant slashes before it.  */
        for (length = strlen(file)-1; 0 < length; length--)
                if (file[length] == '/' && file[length-1] != '/')
                        break;
        return length;
}

static char *convert_abs_rel(const char *from, const char *target)
{
        /* we use the 4*MAXPATHLEN, which should not overrun */
        char relative_from[MAXPATHLEN * 4];
        _cleanup_free_ char *realtarget = NULL;
        _cleanup_free_ char *target_dir_p = NULL, *realpath_p = NULL;
        const char *realfrom = from;
        int level = 0, fromlevel = 0, targetlevel = 0;
        int l, i, rl;
        int dirlen;

        target_dir_p = strdup(target);
        if (!target_dir_p)
                return strdup(from);

        dirlen = dir_len(target_dir_p);
        target_dir_p[dirlen] = '\0';
        realpath_p = realpath(target_dir_p, NULL);

        if (realpath_p == NULL) {
                log_warning("convert_abs_rel(): target '%s' directory has no realpath.", target);
                return strdup(from);
        }

        /* dir_len() skips double /'s e.g. //lib64, so we can't skip just one
         * character - need to skip all leading /'s */
        rl = strlen(target);
        for (i = dirlen+1; i < rl; ++i)
            if (target_dir_p[i] != '/')
                break;
        asprintf(&realtarget, "%s/%s", realpath_p, &target_dir_p[i]);

        /* now calculate the relative path from <from> to <target> and
           store it in <relative_from>
         */
        relative_from[0] = 0;
        rl = 0;

        /* count the pathname elements of realtarget */
        for (targetlevel = 0, i = 0; realtarget[i]; i++)
                if (realtarget[i] == '/')
                        targetlevel++;

        /* count the pathname elements of realfrom */
        for (fromlevel = 0, i = 0; realfrom[i]; i++)
                if (realfrom[i] == '/')
                        fromlevel++;

        /* count the pathname elements, which are common for both paths */
        for (level = 0, i = 0; realtarget[i] && (realtarget[i] == realfrom[i]); i++)
                if (realtarget[i] == '/')
                        level++;

        /* add "../" to the relative_from path, until the common pathname is
           reached */
        for (i = level; i < targetlevel; i++) {
                if (i != level)
                        relative_from[rl++] = '/';
                relative_from[rl++] = '.';
                relative_from[rl++] = '.';
        }

        /* set l to the next uncommon pathname element in realfrom */
        for (l = 1, i = 1; i < level; i++)
                for (l++; realfrom[l] && realfrom[l] != '/'; l++) ;
        /* skip next '/' */
        l++;

        /* append the uncommon rest of realfrom to the relative_from path */
        for (i = level; i <= fromlevel; i++) {
                if (rl)
                        relative_from[rl++] = '/';
                while (realfrom[l] && realfrom[l] != '/')
                        relative_from[rl++] = realfrom[l++];
                l++;
        }

        relative_from[rl] = 0;
        return strdup(relative_from);
}

static int ln_r(const char *src, const char *dst)
{
        int ret;
        _cleanup_free_ const char *points_to = convert_abs_rel(src, dst);

        log_info("ln -s '%s' '%s'", points_to, dst);
        ret = symlink(points_to, dst);

        if (ret != 0) {
                log_error("ERROR: ln -s '%s' '%s': %m", points_to, dst);
                return 1;
        }

        return 0;
}

/* Perform the O(1) btrfs clone operation, if possible.
   Upon success, return 0.  Otherwise, return -1 and set errno.  */
static inline int clone_file(int dest_fd, int src_fd)
{
#undef BTRFS_IOCTL_MAGIC
#define BTRFS_IOCTL_MAGIC 0x94
#undef BTRFS_IOC_CLONE
#define BTRFS_IOC_CLONE _IOW (BTRFS_IOCTL_MAGIC, 9, int)
        return ioctl(dest_fd, BTRFS_IOC_CLONE, src_fd);
}

static bool use_clone = true;

static int cp(const char *src, const char *dst)
{
        int pid;
        int ret = 0;

        if (use_clone) {
                struct stat sb;
                _cleanup_close_ int dest_desc = -1, source_desc = -1;

                if (lstat(src, &sb) != 0)
                        goto normal_copy;

                if (S_ISLNK(sb.st_mode))
                        goto normal_copy;

                source_desc = open(src, O_RDONLY | O_CLOEXEC);
                if (source_desc < 0)
                        goto normal_copy;

                dest_desc =
                    open(dst, O_WRONLY | O_CREAT | O_EXCL | O_CLOEXEC,
                         (sb.st_mode) & (S_ISUID | S_ISGID | S_ISVTX | S_IRWXU | S_IRWXG | S_IRWXO));

                if (dest_desc < 0) {
                        goto normal_copy;
                }

                ret = clone_file(dest_desc, source_desc);

                if (ret == 0) {
                        struct timeval tv[2];
                        if (fchown(dest_desc, sb.st_uid, sb.st_gid) != 0)
                                fchown(dest_desc, -1, sb.st_gid);
                        tv[0].tv_sec = sb.st_atime;
                        tv[0].tv_usec = 0;
                        tv[1].tv_sec = sb.st_mtime;
                        tv[1].tv_usec = 0;
                        futimes(dest_desc, tv);
                        return ret;
                }
                close(dest_desc);
                dest_desc = -1;
                /* clone did not work, remove the file */
                unlink(dst);
                /* do not try clone again */
                use_clone = false;
        }

 normal_copy:
        pid = fork();
        if (pid == 0) {
                execlp("cp", "cp", "--reflink=auto", "--sparse=auto", "--preserve=mode,timestamps", "-fL", src, dst, NULL);
                _exit(EXIT_FAILURE);
        }

        while (waitpid(pid, &ret, 0) < 0) {
                if (errno != EINTR) {
                        ret = -1;
                        log_error("Failed: cp --reflink=auto --sparse=auto --preserve=mode,timestamps -fL %s %s", src, dst);
                        break;
                }
        }
        log_debug("cp ret = %d", ret);
        return ret;
}

static int resolve_deps(const char *src)
{
        int ret = 0;

        char *buf = malloc(LINE_MAX);
        size_t linesize = LINE_MAX;
        _cleanup_pclose_ FILE *fptr = NULL;
        _cleanup_free_ char *cmd = NULL;

        if (strstr(src, ".so") == 0) {
                _cleanup_close_ int fd = -1;
                fd = open(src, O_RDONLY | O_CLOEXEC);
                if (fd < 0)
                        return -errno;

                read(fd, buf, LINE_MAX);
                buf[LINE_MAX - 1] = '\0';
                if (buf[0] == '#' && buf[1] == '!') {
                        /* we have a shebang */
                        char *p, *q;
                        for (p = &buf[2]; *p && isspace(*p); p++) ;
                        for (q = p; *q && (!isspace(*q)); q++) ;
                        *q = '\0';
                        log_debug("Script install: '%s'", p);
                        ret = dracut_install(p, p, false, true, false);
                        if (ret != 0)
                                log_error("ERROR: failed to install '%s'", p);
                        return ret;
                }
        }

        /* run ldd */
        ret = asprintf(&cmd, "ldd %s 2>&1", src);
        if (ret < 0)
                return ret;
        ret = 0;

        fptr = popen(cmd, "r");

        while (!feof(fptr)) {
                char *p, *q;

                if (getline(&buf, &linesize, fptr) <= 0)
                        continue;

                log_debug("ldd: '%s'", buf);

                if (strstr(buf, "you do not have execution permission")) {
                        log_error(buf);
                        ret+=1;
                        break;
                }

                if (strstr(buf, "not a dynamic executable"))
                        break;

                if (strstr(buf, "loader cannot load itself"))
                        break;

                if (strstr(buf, "not regular file"))
                        break;

                if (strstr(buf, "cannot read header"))
                        break;

                if (strstr(buf, destrootdir))
                        break;

                p = strstr(buf, "/");
                if (p) {
                        int r;
                        for (q = p; *q && *q != ' ' && *q != '\n'; q++) ;
                        *q = '\0';
                        r = dracut_install(p, p, false, false, true);
                        if (r != 0)
                                log_error("ERROR: failed to install '%s' for '%s'", p, src);
                        else
                                log_debug("Lib install: '%s'", p);
                        ret += r;

                        /* also install lib.so for lib.so.* files */
                        q = strstr(p, ".so.");
                        if (q) {
                                q += 3;
                                *q = '\0';

                                /* ignore errors for base lib symlink */
                                if (dracut_install(p, p, false, false, true) == 0)
                                        log_debug("Lib install: '%s'", p);
                        }
                }
        }

        return ret;
}

/* Install ".<filename>.hmac" file for FIPS self-checks */
static int hmac_install(const char *src, const char *dst, const char *hmacpath)
{
        _cleanup_free_ char *srcpath = strdup(src);
        _cleanup_free_ char *dstpath = strdup(dst);
        _cleanup_free_ char *srchmacname = NULL;
        _cleanup_free_ char *dsthmacname = NULL;

        if (!(srcpath && dstpath))
                return -ENOMEM;

        size_t dlen = dir_len(src);

        if (endswith(src, ".hmac"))
                return 0;

	if (!hmacpath) {
                hmac_install(src, dst, "/lib/fipscheck");
                hmac_install(src, dst, "/lib64/fipscheck");
                hmac_install(src, dst, "/lib/hmaccalc");
                hmac_install(src, dst, "/lib64/hmaccalc");
        }

        srcpath[dlen] = '\0';
        dstpath[dir_len(dst)] = '\0';
        if (hmacpath) {
                asprintf(&srchmacname, "%s/%s.hmac", hmacpath, &src[dlen + 1]);
                asprintf(&dsthmacname, "%s/%s.hmac", hmacpath, &src[dlen + 1]);
        } else {
                asprintf(&srchmacname, "%s/.%s.hmac", srcpath, &src[dlen + 1]);
                asprintf(&dsthmacname, "%s/.%s.hmac", dstpath, &src[dlen + 1]);
        }
        log_debug("hmac cp '%s' '%s')", srchmacname, dsthmacname);
        dracut_install(srchmacname, dsthmacname, false, false, true);
        return 0;
}

static int dracut_install(const char *src, const char *dst, bool isdir, bool resolvedeps, bool hashdst)
{
        struct stat sb, db;
        _cleanup_free_ char *fulldstpath = NULL;
        _cleanup_free_ char *fulldstdir = NULL;
        int ret;
        bool src_exists = true;
        char *i = NULL;
        char *existing;

        log_debug("dracut_install('%s', '%s')", src, dst);

        existing = hashmap_get(items_failed, src);
        if (existing) {
                if (strcmp(existing, src) == 0) {
                        log_debug("hash hit items_failed for '%s'", src);
                        return 1;
                }
        }

        if (hashdst) {
                existing = hashmap_get(items, dst);
                if (existing) {
                        if (strcmp(existing, dst) == 0) {
                                log_debug("hash hit items for '%s'", dst);
                                return 0;
                        }
                }
        }

        if (lstat(src, &sb) < 0) {
                src_exists = false;
                if (!isdir) {
                        i = strdup(src);
                        hashmap_put(items_failed, i, i);
                        /* src does not exist */
                        return 1;
                }
        }

        i = strdup(dst);
        if (!i)
                return -ENOMEM;

        hashmap_put(items, i, i);

        asprintf(&fulldstpath, "%s%s", destrootdir, dst);

        ret = stat(fulldstpath, &sb);

        if (ret != 0 && (errno != ENOENT)) {
                log_error("ERROR: stat '%s': %m", fulldstpath);
                return 1;
        }

        if (ret == 0) {
                if (resolvedeps && S_ISREG(sb.st_mode) && (sb.st_mode & (S_IXUSR | S_IXGRP | S_IXOTH))) {
                        log_debug("'%s' already exists, but checking for any deps", fulldstpath);
                        ret = resolve_deps(src);
                } else
                        log_debug("'%s' already exists", fulldstpath);

                /* dst does already exist */
                return ret;
        }

        /* check destination directory */
        fulldstdir = strdup(fulldstpath);
        fulldstdir[dir_len(fulldstdir)] = '\0';

        ret = stat(fulldstdir, &db);

        if (ret < 0) {
                _cleanup_free_ char *dname = NULL;

                if (errno != ENOENT) {
                        log_error("ERROR: stat '%s': %m", fulldstdir);
                        return 1;
                }
                /* create destination directory */
                log_debug("dest dir '%s' does not exist", fulldstdir);
                dname = strdup(dst);
                if (!dname)
                        return 1;

                dname[dir_len(dname)] = '\0';
                ret = dracut_install(dname, dname, true, false, true);

                if (ret != 0) {
                        log_error("ERROR: failed to create directory '%s'", fulldstdir);
                        return 1;
                }
        }

        if (isdir && !src_exists) {
                log_info("mkdir '%s'", fulldstpath);
                ret = mkdir(fulldstpath, 0755);
                return ret;
        }

        /* ready to install src */

        if (S_ISDIR(sb.st_mode)) {
                log_info("mkdir '%s'", fulldstpath);
                ret = mkdir(fulldstpath, sb.st_mode | S_IWUSR);
                return ret;
        }

        if (S_ISLNK(sb.st_mode)) {
                _cleanup_free_ char *abspath = NULL;

                abspath = realpath(src, NULL);

                if (abspath == NULL)
                        return 1;

                if (dracut_install(abspath, abspath, false, resolvedeps, hashdst)) {
                        log_debug("'%s' install error", abspath);
                        return 1;
                }

                if (lstat(abspath, &sb) != 0) {
                        log_debug("lstat '%s': %m", abspath);
                        return 1;
                }

                if (lstat(fulldstpath, &sb) != 0) {
                        _cleanup_free_ char *absdestpath = NULL;

                        asprintf(&absdestpath, "%s%s", destrootdir, abspath);

                        ln_r(absdestpath, fulldstpath);
                }

                if (arg_hmac) {
                        /* copy .hmac files also */
                        hmac_install(src, dst, NULL);
                }

                return 0;
        }

        if (sb.st_mode & (S_IXUSR | S_IXGRP | S_IXOTH)) {
                if (resolvedeps)
                        ret += resolve_deps(src);
                if (arg_hmac) {
                        /* copy .hmac files also */
                        hmac_install(src, dst, NULL);
                }
        }

        log_debug("dracut_install ret = %d", ret);
        log_info("cp '%s' '%s'", src, fulldstpath);
        ret += cp(src, fulldstpath);

        log_debug("dracut_install ret = %d", ret);

        return ret;
}

static void item_free(char *i)
{
        assert(i);
        free(i);
}

static void usage(int status)
{        
             /*                                                                     */
        printf("Usage: %s -D DESTROOTDIR [OPTION]... -a SOURCE...\n"
               "or: %s -D DESTROOTDIR [OPTION]... SOURCE DEST\n"
               "\n"
               "Install SOURCE to DEST in DESTROOTDIR with all needed dependencies.\n"
               "\n"
               "  -D --destrootdir    Install all files to DESTROOTDIR as the root\n"
               "  -a --all            Install all SOURCE arguments to DESTROOTDIR\n"
               "  -o --optional       If SOURCE does not exist, do not fail\n"
               "  -d --dir            SOURCE is a directory\n"
               "  -l --ldd            Also install shebang executables and libraries\n"
               "  -R --resolvelazy    Only install shebang executables and libraries\n"
               "                      for all SOURCE files\n"
               "  -H --fips           Also install all '.SOURCE.hmac' files\n"
               "  -v --verbose        Show more output\n"
               "     --debug          Show debug output\n"
               "     --version        Show package version\n"
               "  -h --help           Show this help\n"
               "\n"
               "Example:\n"
               "# mkdir -p /var/tmp/test-root\n"
               "# %s -D /var/tmp/test-root --ldd -a sh tr\n"
               "# tree /var/tmp/test-root\n"
               "/var/tmp/test-root\n"
               "|-- lib64 -> usr/lib64\n"
               "`-- usr\n"
               "    |-- bin\n"
               "    |   |-- bash\n"
               "    |   |-- sh -> bash\n"
               "    |   `-- tr\n"
               "    `-- lib64\n"
               "        |-- ld-2.15.90.so\n"
               "        |-- ld-linux-x86-64.so.2 -> ld-2.15.90.so\n"
               "        |-- libc-2.15.90.so\n"
               "        |-- libc.so\n"
               "        |-- libc.so.6 -> libc-2.15.90.so\n"
               "        |-- libdl-2.15.90.so\n"
               "        |-- libdl.so -> libdl-2.15.90.so\n"
               "        |-- libdl.so.2 -> libdl-2.15.90.so\n"
               "        |-- libtinfo.so.5 -> libtinfo.so.5.9\n"
               "        `-- libtinfo.so.5.9\n"
               , program_invocation_short_name, program_invocation_short_name, program_invocation_short_name);
        exit(status);
}

static int parse_argv(int argc, char *argv[])
{
        int c;

        enum {
                ARG_VERSION = 0x100,
                ARG_DEBUG
        };

        static struct option const options[] = {
                {"help", no_argument, NULL, 'h'},
                {"version", no_argument, NULL, ARG_VERSION},
                {"dir", no_argument, NULL, 'd'},
                {"debug", no_argument, NULL, ARG_DEBUG},
                {"verbose", no_argument, NULL, 'v'},
                {"ldd", no_argument, NULL, 'l'},
                {"resolvelazy", no_argument, NULL, 'R'},
                {"optional", no_argument, NULL, 'o'},
                {"all", no_argument, NULL, 'a'},
                {"fips", no_argument, NULL, 'H'},
                {"destrootdir", required_argument, NULL, 'D'},
                {NULL, 0, NULL, 0}
        };

        while ((c = getopt_long(argc, argv, "adhloD:HR", options, NULL)) != -1) {
                switch (c) {
                case ARG_VERSION:
                        puts(PROGRAM_VERSION_STRING);
                        return 0;
                case 'd':
                        arg_createdir = true;
                        break;
                case ARG_DEBUG:
                        arg_loglevel = LOG_DEBUG;
                        break;
                case 'v':
                        arg_loglevel = LOG_INFO;
                        break;
                case 'o':
                        arg_optional = true;
                        break;
                case 'l':
                        arg_resolvedeps = true;
                        break;
                case 'R':
                        arg_resolvelazy = true;
                        break;
                case 'a':
                        arg_all = true;
                        break;
                case 'D':
                        destrootdir = strdup(optarg);
                        break;
                case 'H':
                        arg_hmac = true;
                        break;
                case 'h':
                        usage(EXIT_SUCCESS);
                        break;
                default:
                        usage(EXIT_FAILURE);
                }
        }

        if (!optind || optind == argc) {
                log_error("No SOURCE argument given");
                usage(EXIT_FAILURE);
        }

        return 1;
}

static int resolve_lazy(int argc, char **argv)
{
        int i;
        int destrootdirlen = strlen(destrootdir);
        int ret = 0;
        char *item;
        for (i = 0; i < argc; i++) {
                const char *src = argv[i];
                char *p = argv[i];
                char *existing;

                log_debug("resolve_deps('%s')", src);

                if (strstr(src, destrootdir)) {
                        p = &argv[i][destrootdirlen];
                }

                existing = hashmap_get(items, p);
                if (existing) {
                        if (strcmp(existing, p) == 0)
                                continue;
                }

                item = strdup(p);
                hashmap_put(items, item, item);

                ret += resolve_deps(src);
        }
        return ret;
}

static char *find_binary(const char *src)
{
        _cleanup_free_ char *path = NULL;
        char *p, *q;
        bool end = false;
        char *newsrc = NULL;
        path = getenv("PATH");

        if (path == NULL) {
                log_error("PATH is not set");
                exit(EXIT_FAILURE);
        }
        path = strdup(path);
        p = path;

        if (path == NULL) {
                log_error("Out of memory!");
                exit(EXIT_FAILURE);
        }

        log_debug("PATH=%s", path);

        do {
                struct stat sb;

                for (q = p; *q && *q != ':'; q++) ;

                if (*q == '\0')
                        end = true;
                else
                        *q = '\0';

                asprintf(&newsrc, "%s/%s", p, src);
                if (newsrc == NULL) {
                        log_error("Out of memory!");
                        exit(EXIT_FAILURE);
                }

                p = q + 1;

                if (stat(newsrc, &sb) != 0) {
                        log_debug("stat(%s) != 0", newsrc);
                        free(newsrc);
                        newsrc = NULL;
                        continue;
                }

                end = true;

        } while (!end);

        if (newsrc)
                log_debug("find_binary(%s) == %s", src, newsrc);

        return newsrc;
}

static int install_one(const char *src, const char *dst)
{
        int r = 0;
        int ret;

        if (strchr(src, '/') == NULL) {
                char *newsrc = find_binary(src);
                if (newsrc) {
                        log_debug("dracut_install '%s' '%s'", newsrc, dst);
                        ret = dracut_install(newsrc, dst, arg_createdir, arg_resolvedeps, true);
                        if (ret == 0) {
                                log_debug("dracut_install '%s' '%s' OK", newsrc, dst);
                        }
                        free(newsrc);
                } else {
                        ret = -1;
                }
        } else {
                ret = dracut_install(src, dst, arg_createdir, arg_resolvedeps, true);
        }

        if ((ret != 0) && (!arg_optional)) {
                log_error("ERROR: installing '%s' to '%s'", src, dst);
                r = EXIT_FAILURE;
        }

        return r;
}

static int install_all(int argc, char **argv)
{
        int r = 0;
        int i;
        for (i = 0; i < argc; i++) {
                int ret;
                log_debug("Handle '%s'", argv[i]);

                if (strchr(argv[i], '/') == NULL) {
                        _cleanup_free_ char *newsrc = find_binary(argv[i]);
                        if (newsrc) {
                                log_debug("dracut_install '%s'", newsrc);
                                ret = dracut_install(newsrc, newsrc, arg_createdir, arg_resolvedeps, true);
                                if (ret == 0) {
                                        log_debug("dracut_install '%s' OK", newsrc);
                                }
                        } else {
                                ret = -1;
                        }

                } else {
                        _cleanup_free_ char *dest = strdup(argv[i]);
                        ret = dracut_install(argv[i], dest, arg_createdir, arg_resolvedeps, true);
                }

                if ((ret != 0) && (!arg_optional)) {
                        log_error("ERROR: installing '%s'", argv[i]);
                        r = EXIT_FAILURE;
                }
        }
        return r;
}

int main(int argc, char **argv)
{
        int r;
        char *i;

        r = parse_argv(argc, argv);
        if (r <= 0)
                return r < 0 ? EXIT_FAILURE : EXIT_SUCCESS;

        log_set_target(LOG_TARGET_CONSOLE);
        log_parse_environment();

        if (arg_loglevel >= 0)
                log_set_max_level(arg_loglevel);

        log_open();

        umask(0022);

        if (destrootdir == NULL || strlen(destrootdir) == 0) {
                destrootdir = getenv("DESTROOTDIR");
                if (destrootdir == NULL || strlen(destrootdir) == 0) {
                        log_error("Environment DESTROOTDIR or argument -D is not set!");
                        usage(EXIT_FAILURE);
                }
                destrootdir = strdup(destrootdir);
        }

        if (strcmp(destrootdir, "/") == 0) {
                log_error("Environment DESTROOTDIR or argument -D is set to '/'!");
                usage(EXIT_FAILURE);
        }

        i = destrootdir;
        destrootdir = realpath(destrootdir, NULL);
        if (!destrootdir) {
                log_error("Environment DESTROOTDIR or argument -D is set to '%s': %m", i);
                r = EXIT_FAILURE;
                goto finish;
        }
        free(i);

        items = hashmap_new(string_hash_func, string_compare_func);
        items_failed = hashmap_new(string_hash_func, string_compare_func);

        if (!items || !items_failed) {
                log_error("Out of memory");
                r = EXIT_FAILURE;
                goto finish;
        }

        r = EXIT_SUCCESS;

        if (((optind + 1) < argc) && (strcmp(argv[optind + 1], destrootdir) == 0)) {
                /* ugly hack for compat mode "inst src $destrootdir" */
                if ((optind + 2) == argc) {
                        argc--;
                } else {
                        /* ugly hack for compat mode "inst src $destrootdir dst" */
                        if ((optind + 3) == argc) {
                                argc--;
                                argv[optind + 1] = argv[optind + 2];
                        }
                }
        }

        if (arg_resolvelazy) {
                r = resolve_lazy(argc - optind, &argv[optind]);
        } else if (arg_all || (argc - optind > 2) || ((argc - optind) == 1)) {
                r = install_all(argc - optind, &argv[optind]);
        } else {
                /* simple "inst src dst" */
                r = install_one(argv[optind], argv[optind + 1]);
        }

        if (arg_optional)
                r = EXIT_SUCCESS;

 finish:

        while ((i = hashmap_steal_first(items)))
                item_free(i);

        while ((i = hashmap_steal_first(items_failed)))
                item_free(i);

        hashmap_free(items);
        hashmap_free(items_failed);

        free(destrootdir);

        return r;
}
