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

#define PROGRAM_VERSION_STRING "2"

#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif
#include <ctype.h>
#include <errno.h>
#include <fcntl.h>
#include <getopt.h>
#include <glob.h>
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
#include <libkmod.h>
#include <fts.h>
#include <regex.h>
#include <sys/utsname.h>

#include "log.h"
#include "hashmap.h"
#include "util.h"
#include "strv.h"

#define _asprintf(strp, fmt, ...) \
        do { \
            if (dracut_asprintf(strp, fmt, __VA_ARGS__) < 0) { \
                    log_error("Out of memory\n"); \
                    exit(EXIT_FAILURE); \
            } \
        } while (0)

static bool arg_hmac = false;
static bool arg_createdir = false;
static int arg_loglevel = -1;
static bool arg_optional = false;
static bool arg_silent = false;
static bool arg_all = false;
static bool arg_module = false;
static bool arg_modalias = false;
static bool arg_resolvelazy = false;
static bool arg_resolvedeps = false;
static bool arg_hostonly = false;
static bool no_xattr = false;
static char *destrootdir = NULL;
static char *sysrootdir = NULL;
static size_t sysrootdirlen = 0;
static char *kerneldir = NULL;
static size_t kerneldirlen = 0;
static char **firmwaredirs = NULL;
static char **pathdirs;
static char *ldd = NULL;
static char *logdir = NULL;
static char *logfile = NULL;
FILE *logfile_f = NULL;
static Hashmap *items = NULL;
static Hashmap *items_failed = NULL;
static Hashmap *modules_loaded = NULL;
static Hashmap *modules_suppliers = NULL;
static Hashmap *processed_suppliers = NULL;
static regex_t mod_filter_path;
static regex_t mod_filter_nopath;
static regex_t mod_filter_symbol;
static regex_t mod_filter_nosymbol;
static regex_t mod_filter_noname;
static bool arg_mod_filter_path = false;
static bool arg_mod_filter_nopath = false;
static bool arg_mod_filter_symbol = false;
static bool arg_mod_filter_nosymbol = false;
static bool arg_mod_filter_noname = false;

static int dracut_install(const char *src, const char *dst, bool isdir, bool resolvedeps, bool hashdst);
static int install_dependent_modules(struct kmod_ctx *ctx, struct kmod_list *modlist, Hashmap *suppliers_paths);

static void item_free(char *i)
{
        assert(i);
        free(i);
}

static inline void kmod_module_unrefp(struct kmod_module **p)
{
        if (*p)
                kmod_module_unref(*p);
}

#define _cleanup_kmod_module_unref_ _cleanup_(kmod_module_unrefp)

static inline void kmod_module_unref_listp(struct kmod_list **p)
{
        if (*p)
                kmod_module_unref_list(*p);
}

#define _cleanup_kmod_module_unref_list_ _cleanup_(kmod_module_unref_listp)

static inline void kmod_module_info_free_listp(struct kmod_list **p)
{
        if (*p)
                kmod_module_info_free_list(*p);
}

#define _cleanup_kmod_module_info_free_list_ _cleanup_(kmod_module_info_free_listp)

static inline void kmod_unrefp(struct kmod_ctx **p)
{
        kmod_unref(*p);
}

#define _cleanup_kmod_unref_ _cleanup_(kmod_unrefp)

static inline void kmod_module_dependency_symbols_free_listp(struct kmod_list **p)
{
        if (*p)
                kmod_module_dependency_symbols_free_list(*p);
}

#define _cleanup_kmod_module_dependency_symbols_free_list_ _cleanup_(kmod_module_dependency_symbols_free_listp)

static inline void fts_closep(FTS **p)
{
        if (*p)
                fts_close(*p);
}

#define _cleanup_fts_close_ _cleanup_(fts_closep)

#define _cleanup_globfree_ _cleanup_(globfree)

static inline void destroy_hashmap(Hashmap **hashmap)
{
        void *i = NULL;

        while ((i = hashmap_steal_first(*hashmap)))
                item_free(i);

        hashmap_free(*hashmap);
}

#define _cleanup_destroy_hashmap_ _cleanup_(destroy_hashmap)

static size_t dir_len(char const *file)
{
        size_t length;

        if (!file)
                return 0;

        /* Strip the basename and any redundant slashes before it.  */
        for (length = strlen(file) - 1; 0 < length; length--)
                if (file[length] == '/' && file[length - 1] != '/')
                        break;
        return length;
}

static char *convert_abs_rel(const char *from, const char *target)
{
        /* we use the 4*MAXPATHLEN, which should not overrun */
        char buf[MAXPATHLEN * 4];
        _cleanup_free_ char *realtarget = NULL, *realfrom = NULL, *from_dir_p = NULL;
        _cleanup_free_ char *target_dir_p = NULL;
        size_t level = 0, fromlevel = 0, targetlevel = 0;
        int l;
        size_t i, rl, dirlen;

        dirlen = dir_len(from);
        from_dir_p = strndup(from, dirlen);
        if (!from_dir_p)
                return strdup(from + strlen(destrootdir));
        if (realpath(from_dir_p, buf) == NULL) {
                log_warning("convert_abs_rel(): from '%s' directory has no realpath: %m", from);
                return strdup(from + strlen(destrootdir));
        }
        /* dir_len() skips double /'s e.g. //lib64, so we can't skip just one
         * character - need to skip all leading /'s */
        for (i = dirlen + 1; from[i] == '/'; ++i)
                ;
        _asprintf(&realfrom, "%s/%s", buf, from + i);

        dirlen = dir_len(target);
        target_dir_p = strndup(target, dirlen);
        if (!target_dir_p)
                return strdup(from + strlen(destrootdir));
        if (realpath(target_dir_p, buf) == NULL) {
                log_warning("convert_abs_rel(): target '%s' directory has no realpath: %m", target);
                return strdup(from + strlen(destrootdir));
        }

        for (i = dirlen + 1; target[i] == '/'; ++i)
                ;
        _asprintf(&realtarget, "%s/%s", buf, target + i);

        /* now calculate the relative path from <from> to <target> and
           store it in <buf>
         */
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

        /* add "../" to the buf path, until the common pathname is
           reached */
        for (i = level; i < targetlevel; i++) {
                if (i != level)
                        buf[rl++] = '/';
                buf[rl++] = '.';
                buf[rl++] = '.';
        }

        /* set l to the next uncommon pathname element in realfrom */
        for (l = 1, i = 1; i < level; i++)
                for (l++; realfrom[l] && realfrom[l] != '/'; l++) ;
        /* skip next '/' */
        l++;

        /* append the uncommon rest of realfrom to the buf path */
        for (i = level; i <= fromlevel; i++) {
                if (rl)
                        buf[rl++] = '/';
                while (realfrom[l] && realfrom[l] != '/')
                        buf[rl++] = realfrom[l++];
                l++;
        }

        buf[rl] = 0;
        return strdup(buf);
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
                                if (fchown(dest_desc, (uid_t) - 1, sb.st_gid) != 0) {
                                        if (geteuid() == 0)
                                                log_error("Failed to chown %s: %m", dst);
                                        else
                                                log_info("Failed to chown %s: %m", dst);
                                }

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
        const char *preservation = (geteuid() == 0
                                    && no_xattr == false) ? "--preserve=mode,xattr,timestamps,ownership" : "--preserve=mode,timestamps,ownership";
        if (pid == 0) {
                execlp("cp", "cp", "--reflink=auto", "--sparse=auto", preservation, "-fL", src, dst, NULL);
                _exit(errno == ENOENT ? 127 : 126);
        }

        while (waitpid(pid, &ret, 0) == -1) {
                if (errno != EINTR) {
                        log_error("ERROR: waitpid() failed: %m");
                        return 1;
                }
        }
        ret = WIFSIGNALED(ret) ? 128 + WTERMSIG(ret) : WEXITSTATUS(ret);
        if (ret != 0)
                log_error("ERROR: 'cp --reflink=auto --sparse=auto %s -fL %s %s' failed with %d", preservation, src, dst, ret);
        log_debug("cp ret = %d", ret);
        return ret;
}

static int library_install(const char *src, const char *lib)
{
        _cleanup_free_ char *p = NULL;
        _cleanup_free_ char *pdir = NULL, *ppdir = NULL, *pppdir = NULL, *clib = NULL;
        char *q, *clibdir;
        int r, ret = 0;

        r = dracut_install(lib, lib, false, false, true);
        if (r != 0)
                log_error("ERROR: failed to install '%s' for '%s'", lib, src);
        else
                log_debug("Lib install: '%s'", lib);
        ret += r;

        /* also install lib.so for lib.so.* files */
        q = strstr(lib, ".so.");
        if (q) {
                p = strndup(lib, q - lib + 3);

                /* ignore errors for base lib symlink */
                if (dracut_install(p, p, false, false, true) == 0)
                        log_debug("Lib install: '%s'", p);

                free(p);
        }

        /* Also try to install the same library from one directory above
         * or from one directory above glibc-hwcaps.
           This fixes the case, where only the HWCAP lib would be installed
           # ldconfig -p|grep -F libc.so
           libc.so.6 (libc6,64bit, hwcap: 0x0000001000000000, OS ABI: Linux 2.6.32) => /lib64/power6/libc.so.6
           libc.so.6 (libc6,64bit, hwcap: 0x0000000000000200, OS ABI: Linux 2.6.32) => /lib64/power6x/libc.so.6
           libc.so.6 (libc6,64bit, OS ABI: Linux 2.6.32) => /lib64/libc.so.6
         */

        p = strdup(lib);

        pdir = dirname_malloc(p);
        if (!pdir)
                return ret;

        ppdir = dirname_malloc(pdir);
        /* only one parent directory, not HWCAP library */
        if (!ppdir || streq(ppdir, "/"))
                return ret;

        pppdir = dirname_malloc(ppdir);
        if (!pppdir)
                return ret;

        clibdir = streq(basename(ppdir), "glibc-hwcaps") ? pppdir : ppdir;
        clib = strjoin(clibdir, "/", basename(p), NULL);
        if (dracut_install(clib, clib, false, false, true) == 0)
                log_debug("Lib install: '%s'", clib);
        /* also install lib.so for lib.so.* files */
        q = strstr(clib, ".so.");
        if (q) {
                q[3] = '\0';

                /* ignore errors for base lib symlink */
                if (dracut_install(clib, clib, false, false, true) == 0)
                        log_debug("Lib install: '%s'", p);
        }

        return ret;
}

static char *get_real_file(const char *src, bool fullyresolve)
{
        struct stat sb;
        ssize_t linksz;
        char linktarget[PATH_MAX + 1];
        _cleanup_free_ char *fullsrcpath_a = NULL;
        const char *fullsrcpath;
        _cleanup_free_ char *abspath = NULL;

        if (sysrootdirlen) {
                if (strncmp(src, sysrootdir, sysrootdirlen) == 0) {
                        fullsrcpath = src;
                } else {
                        _asprintf(&fullsrcpath_a, "%s/%s",
                                  (sysrootdirlen ? sysrootdir : ""),
                                  (src[0] == '/' ? src + 1 : src));
                        fullsrcpath = fullsrcpath_a;
                }
        } else {
                fullsrcpath = src;
        }

        log_debug("get_real_file('%s')", fullsrcpath);

        if (lstat(fullsrcpath, &sb) < 0)
                return NULL;

        switch (sb.st_mode & S_IFMT) {
        case S_IFDIR:
        case S_IFREG:
                return strdup(fullsrcpath);
        case S_IFLNK:
                break;
        default:
                return NULL;
        }

        linksz = readlink(fullsrcpath, linktarget, sizeof(linktarget));
        if (linksz < 0)
                return NULL;
        linktarget[linksz] = '\0';

        log_debug("get_real_file: readlink('%s') returns '%s'", fullsrcpath, linktarget);

        if (streq(fullsrcpath, linktarget)) {
                log_error("ERROR: '%s' is pointing to itself", fullsrcpath);
                return NULL;
        }

        if (linktarget[0] == '/') {
                _asprintf(&abspath, "%s%s", (sysrootdirlen ? sysrootdir : ""), linktarget);
        } else {
                _asprintf(&abspath, "%.*s/%s", (int)dir_len(fullsrcpath), fullsrcpath, linktarget);
        }

        if (fullyresolve) {
                struct stat st;
                if (lstat(abspath, &st) < 0) {
                        if (errno != ENOENT) {
                                return NULL;
                        }
                }
                if (S_ISLNK(st.st_mode)) {
                        return get_real_file(abspath, fullyresolve);
                }
        }

        log_debug("get_real_file('%s') => '%s'", src, abspath);
        return TAKE_PTR(abspath);
}

static int resolve_deps(const char *src)
{
        int ret = 0, err;

        _cleanup_free_ char *buf = NULL;
        size_t linesize = LINE_MAX + 1;
        _cleanup_free_ char *fullsrcpath = NULL;

        fullsrcpath = get_real_file(src, true);
        log_debug("resolve_deps('%s') -> get_real_file('%s', true) = '%s'", src, src, fullsrcpath);
        if (!fullsrcpath)
                return 0;

        buf = malloc(linesize);
        if (buf == NULL)
                return -errno;

        if (strstr(src, ".so") == NULL) {
                _cleanup_close_ int fd = -1;
                fd = open(fullsrcpath, O_RDONLY | O_CLOEXEC);
                if (fd < 0)
                        return -errno;

                ret = read(fd, buf, linesize - 1);
                if (ret == -1)
                        return -errno;

                buf[ret] = '\0';
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

        int fds[2];
        FILE *fptr;
        if (pipe2(fds, O_CLOEXEC) == -1 || (fptr = fdopen(fds[0], "r")) == NULL) {
                log_error("ERROR: pipe stream initialization for '%s' failed: %m", ldd);
                exit(EXIT_FAILURE);
        }

        log_debug("%s %s", ldd, fullsrcpath);
        pid_t ldd_pid;
        if ((ldd_pid = fork()) == 0) {
                dup2(fds[1], 1);
                dup2(fds[1], 2);
                putenv("LC_ALL=C");
                execlp(ldd, ldd, fullsrcpath, (char *)NULL);
                _exit(errno == ENOENT ? 127 : 126);
        }
        close(fds[1]);

        ret = 0;

        while (getline(&buf, &linesize, fptr) >= 0) {
                char *p;

                log_debug("ldd: '%s'", buf);

                if (strstr(buf, "you do not have execution permission")) {
                        log_error("%s", buf);
                        ret += 1;
                        break;
                }

                /* errors from cross-compiler-ldd */
                if (strstr(buf, "unable to find sysroot")) {
                        log_error("%s", buf);
                        ret += 1;
                        break;
                }

                /* musl ldd */
                if (strstr(buf, "Not a valid dynamic program"))
                        break;

                /* glibc */
                if (strstr(buf, "cannot execute binary file"))
                        continue;

                if (strstr(buf, "not a dynamic executable"))
                        break;

                if (strstr(buf, "loader cannot load itself"))
                        break;

                if (strstr(buf, "not regular file"))
                        break;

                if (strstr(buf, "cannot read header"))
                        break;

                if (strstr(buf, "cannot be preloaded"))
                        continue;

                if (strstr(buf, destrootdir))
                        break;

                p = buf;
                if (strchr(p, '$')) {
                        /* take ldd variable expansion into account */
                        p = strstr(p, "=>");
                        if (!p)
                                p = buf;
                }
                p = strchr(p, '/');

                if (p) {
                        char *q;

                        for (q = p; *q && *q != ' ' && *q != '\n'; q++) ;
                        *q = '\0';

                        ret += library_install(src, p);

                }
        }

        fclose(fptr);
        while (waitpid(ldd_pid, &err, 0) == -1) {
                if (errno != EINTR) {
                        log_error("ERROR: waitpid() failed: %m");
                        return 1;
                }
        }
        err = WIFSIGNALED(err) ? 128 + WTERMSIG(err) : WEXITSTATUS(err);
        /* ldd has error conditions we largely don't care about ("not a dynamic executable", &c.):
           only error out on hard errors (ENOENT, ENOEXEC, signals) */
        if (err >= 126) {
                log_error("ERROR: '%s %s' failed with %d", ldd, fullsrcpath, err);
                return err;
        } else
                return ret;
}

/* Install ".<filename>.hmac" file for FIPS self-checks */
static int hmac_install(const char *src, const char *dst, const char *hmacpath)
{
        _cleanup_free_ char *srchmacname = NULL;
        _cleanup_free_ char *dsthmacname = NULL;

        size_t dlen = dir_len(src);

        if (endswith(src, ".hmac"))
                return 0;

        if (!hmacpath) {
                hmac_install(src, dst, "/lib/fipscheck");
                hmac_install(src, dst, "/lib64/fipscheck");
                hmac_install(src, dst, "/lib/hmaccalc");
                hmac_install(src, dst, "/lib64/hmaccalc");
        }

        if (hmacpath) {
                _asprintf(&srchmacname, "%s/%s.hmac", hmacpath, &src[dlen + 1]);
                _asprintf(&dsthmacname, "%s/%s.hmac", hmacpath, &src[dlen + 1]);
        } else {
                _asprintf(&srchmacname, "%.*s/.%s.hmac", (int)dlen,         src, &src[dlen + 1]);
                _asprintf(&dsthmacname, "%.*s/.%s.hmac", (int)dir_len(dst), dst, &src[dlen + 1]);
        }
        log_debug("hmac cp '%s' '%s'", srchmacname, dsthmacname);
        dracut_install(srchmacname, dsthmacname, false, false, true);
        return 0;
}

void mark_hostonly(const char *path)
{
        _cleanup_free_ char *fulldstpath = NULL;
        _cleanup_fclose_ FILE *f = NULL;

        _asprintf(&fulldstpath, "%s/lib/dracut/hostonly-files", destrootdir);

        f = fopen(fulldstpath, "a");

        if (f == NULL) {
                log_error("Could not open '%s' for writing.", fulldstpath);
                return;
        }

        fprintf(f, "%s\n", path);
}

void dracut_log_cp(const char *path)
{
        int ret;
        ret = fprintf(logfile_f, "%s\n", path);
        if (ret < 0)
                log_error("Could not append '%s' to logfile '%s': %m", path, logfile);
}

static bool check_hashmap(Hashmap *hm, const char *item)
{
        char *existing;
        existing = hashmap_get(hm, item);
        if (existing) {
                if (strcmp(existing, item) == 0) {
                        return true;
                }
        }
        return false;
}

static int dracut_mkdir(const char *src)
{
        _cleanup_free_ char *parent = NULL;
        char *path;
        struct stat sb;

        parent = strdup(src);
        if (!parent)
                return 1;

        path = parent[0] == '/' ? parent + 1 : parent;
        while (path) {
                path = strstr(path, "/");
                if (path)
                        *path = '\0';

                if (stat(parent, &sb) == 0) {
                        if (!S_ISDIR(sb.st_mode)) {
                                log_error("%s exists but is not a directory!", parent);
                                return 1;
                        }
                } else if (errno != ENOENT) {
                        log_error("ERROR: stat '%s': %m", parent);
                        return 1;
                } else {
                        if (mkdir(parent, 0755) < 0) {
                                log_error("ERROR: mkdir '%s': %m", parent);
                                return 1;
                        }
                }

                if (path) {
                        *path = '/';
                        path++;
                }
        }

        return 0;
}

static int dracut_install(const char *orig_src, const char *orig_dst, bool isdir, bool resolvedeps, bool hashdst)
{
        struct stat sb;
        _cleanup_free_ char *fullsrcpath = NULL;
        _cleanup_free_ char *fulldstpath = NULL;
        _cleanup_free_ char *fulldstdir = NULL;
        int ret;
        bool src_islink = false;
        bool src_isdir = false;
        mode_t src_mode = 0;
        bool dst_exists = true;
        char *i = NULL;
        const char *src, *dst;

        if (sysrootdirlen) {
                if (strncmp(orig_src, sysrootdir, sysrootdirlen) == 0) {
                        src = orig_src + sysrootdirlen;
                        fullsrcpath = strdup(orig_src);
                } else {
                        src = orig_src;
                        _asprintf(&fullsrcpath, "%s%s", sysrootdir, src);
                }
                if (strncmp(orig_dst, sysrootdir, sysrootdirlen) == 0)
                        dst = orig_dst + sysrootdirlen;
                else
                        dst = orig_dst;
        } else {
                src = orig_src;
                fullsrcpath = strdup(src);
                dst = orig_dst;
        }

        log_debug("dracut_install('%s', '%s', %d, %d, %d)", src, dst, isdir, resolvedeps, hashdst);

        if (check_hashmap(items_failed, src)) {
                log_debug("hash hit items_failed for '%s'", src);
                return 1;
        }

        if (hashdst && check_hashmap(items, dst)) {
                log_debug("hash hit items for '%s'", dst);
                return 0;
        }

        if (lstat(fullsrcpath, &sb) < 0) {
                if (!isdir) {
                        i = strdup(src);
                        hashmap_put(items_failed, i, i);
                        /* src does not exist */
                        return 1;
                }
        } else {
                src_islink = S_ISLNK(sb.st_mode);
                src_isdir = S_ISDIR(sb.st_mode);
                src_mode = sb.st_mode;
        }

        _asprintf(&fulldstpath, "%s/%s", destrootdir, (dst[0] == '/' ? (dst + 1) : dst));

        ret = stat(fulldstpath, &sb);
        if (ret != 0) {
                dst_exists = false;
                if (errno != ENOENT) {
                        log_error("ERROR: stat '%s': %m", fulldstpath);
                        return 1;
                }
        }

        if (ret == 0) {
                if (resolvedeps && S_ISREG(sb.st_mode) && (sb.st_mode & (S_IXUSR | S_IXGRP | S_IXOTH))) {
                        log_debug("'%s' already exists, but checking for any deps", fulldstpath);
                        ret = resolve_deps(fulldstpath + sysrootdirlen);
                } else
                        log_debug("'%s' already exists", fulldstpath);

                /* dst does already exist */
        } else {

                /* check destination directory */
                fulldstdir = strndup(fulldstpath, dir_len(fulldstpath));
                if (!fulldstdir) {
                        log_error("Out of memory!");
                        return 1;
                }

                ret = access(fulldstdir, F_OK);

                if (ret < 0) {
                        _cleanup_free_ char *dname = NULL;

                        if (errno != ENOENT) {
                                log_error("ERROR: stat '%s': %m", fulldstdir);
                                return 1;
                        }
                        /* create destination directory */
                        log_debug("dest dir '%s' does not exist", fulldstdir);

                        dname = strndup(dst, dir_len(dst));
                        if (!dname)
                                return 1;
                        ret = dracut_install(dname, dname, true, false, true);

                        if (ret != 0) {
                                log_error("ERROR: failed to create directory '%s'", fulldstdir);
                                return 1;
                        }
                }

                if (src_isdir) {
                        if (dst_exists) {
                                if (S_ISDIR(sb.st_mode)) {
                                        log_debug("dest dir '%s' already exists", fulldstpath);
                                        return 0;
                                }
                                log_error("dest dir '%s' already exists but is not a directory", fulldstpath);
                                return 1;
                        }

                        log_info("mkdir '%s'", fulldstpath);
                        ret = dracut_mkdir(fulldstpath);
                        if (ret == 0) {
                                i = strdup(dst);
                                if (!i)
                                        return -ENOMEM;

                                hashmap_put(items, i, i);
                        }
                        return ret;
                }

                /* ready to install src */

                if (src_islink) {
                        _cleanup_free_ char *abspath = NULL;

                        abspath = get_real_file(src, false);

                        if (abspath == NULL)
                                return 1;

                        if (dracut_install(abspath, abspath, false, resolvedeps, hashdst)) {
                                log_debug("'%s' install error", abspath);
                                return 1;
                        }

                        if (faccessat(AT_FDCWD, abspath, F_OK, AT_SYMLINK_NOFOLLOW) != 0) {
                                log_debug("lstat '%s': %m", abspath);
                                return 1;
                        }

                        if (faccessat(AT_FDCWD, fulldstpath, F_OK, AT_SYMLINK_NOFOLLOW) != 0) {
                                _cleanup_free_ char *absdestpath = NULL;

                                _asprintf(&absdestpath, "%s/%s", destrootdir,
                                          (abspath[0] == '/' ? (abspath + 1) : abspath) + sysrootdirlen);

                                ln_r(absdestpath, fulldstpath);
                        }

                        if (arg_hmac) {
                                /* copy .hmac files also */
                                hmac_install(src, dst, NULL);
                        }

                        return 0;
                }

                if (src_mode & (S_IXUSR | S_IXGRP | S_IXOTH)) {
                        if (resolvedeps)
                                ret += resolve_deps(fullsrcpath + sysrootdirlen);
                        if (arg_hmac) {
                                /* copy .hmac files also */
                                hmac_install(src, dst, NULL);
                        }
                }

                log_debug("dracut_install ret = %d", ret);

                if (arg_hostonly && !arg_module)
                        mark_hostonly(dst);

                if (isdir) {
                        log_info("mkdir '%s'", fulldstpath);
                        ret += dracut_mkdir(fulldstpath);
                } else {
                        log_info("cp '%s' '%s'", fullsrcpath, fulldstpath);
                        ret += cp(fullsrcpath, fulldstpath);
                }
        }

        if (ret == 0) {
                i = strdup(dst);
                if (!i)
                        return -ENOMEM;

                hashmap_put(items, i, i);

                if (logfile_f)
                        dracut_log_cp(src);
        }

        log_debug("dracut_install ret = %d", ret);

        return ret;
}

static void usage(int status)
{
        /*                                                                                */
        printf("Usage: %s -D DESTROOTDIR [-r SYSROOTDIR] [OPTION]... -a SOURCE...\n"
               "or: %s -D DESTROOTDIR [-r SYSROOTDIR] [OPTION]... SOURCE DEST\n"
               "or: %s -D DESTROOTDIR [-r SYSROOTDIR] [OPTION]... -m KERNELMODULE [KERNELMODULE …]\n"
               "\n"
               "Install SOURCE (from rootfs or SYSROOTDIR) to DEST in DESTROOTDIR with all needed dependencies.\n"
               "\n"
               "  KERNELMODULE can have the format:\n"
               "     <absolute path> with a leading /\n"
               "     =<kernel subdir>[/<kernel subdir>…] like '=drivers/hid'\n"
               "     <module name>\n"
               "\n"
               "  -D --destrootdir  Install all files to DESTROOTDIR as the root\n"
               "  -r --sysrootdir   Install all files from SYSROOTDIR\n"
               "  -a --all          Install all SOURCE arguments to DESTROOTDIR\n"
               "  -o --optional     If SOURCE does not exist, do not fail\n"
               "  -d --dir          SOURCE is a directory\n"
               "  -l --ldd          Also install shebang executables and libraries\n"
               "  -L --logdir <DIR> Log files, which were installed from the host to <DIR>\n"
               "  -R --resolvelazy  Only install shebang executables and libraries\n"
               "                     for all SOURCE files\n"
               "  -H --hostonly     Mark all SOURCE files as hostonly\n\n"
               "  -f --fips         Also install all '.SOURCE.hmac' files\n"
               "\n"
               "  --module,-m       Install kernel modules, instead of files\n"
               "  --kerneldir       Specify the kernel module directory\n"
               "                     (default: /lib/modules/$(uname -r))\n"
               "  --firmwaredirs    Specify the firmware directory search path with : separation\n"
               "                     (default: $DRACUT_FIRMWARE_PATH, otherwise kernel-compatible\n"
               "                      $(</sys/module/firmware_class/parameters/path),\n"
               "                      /lib/firmware/updates/$(uname -r), /lib/firmware/updates\n"
               "                      /lib/firmware/$(uname -r), /lib/firmware)\n"
               "  --silent          Don't display error messages for kernel module install\n"
               "  --modalias        Only generate module list from /sys/devices modalias list\n"
               "  -o --optional     If kernel module does not exist, do not fail\n"
               "  -p --mod-filter-path      Filter kernel modules by path regexp\n"
               "  -P --mod-filter-nopath    Exclude kernel modules by path regexp\n"
               "  -s --mod-filter-symbol    Filter kernel modules by symbol regexp\n"
               "  -S --mod-filter-nosymbol  Exclude kernel modules by symbol regexp\n"
               "  -N --mod-filter-noname    Exclude kernel modules by name regexp\n"
               "\n"
               "  -v --verbose      Show more output\n"
               "     --debug        Show debug output\n"
               "     --version      Show package version\n"
               "  -h --help         Show this help\n"
               "\n", program_invocation_short_name, program_invocation_short_name, program_invocation_short_name);
        exit(status);
}

static int parse_argv(int argc, char *argv[])
{
        int c;

        enum {
                ARG_VERSION = 0x100,
                ARG_SILENT,
                ARG_MODALIAS,
                ARG_KERNELDIR,
                ARG_FIRMWAREDIRS,
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
                {"hostonly", no_argument, NULL, 'H'},
                {"all", no_argument, NULL, 'a'},
                {"module", no_argument, NULL, 'm'},
                {"fips", no_argument, NULL, 'f'},
                {"destrootdir", required_argument, NULL, 'D'},
                {"sysrootdir", required_argument, NULL, 'r'},
                {"logdir", required_argument, NULL, 'L'},
                {"mod-filter-path", required_argument, NULL, 'p'},
                {"mod-filter-nopath", required_argument, NULL, 'P'},
                {"mod-filter-symbol", required_argument, NULL, 's'},
                {"mod-filter-nosymbol", required_argument, NULL, 'S'},
                {"mod-filter-noname", required_argument, NULL, 'N'},
                {"modalias", no_argument, NULL, ARG_MODALIAS},
                {"silent", no_argument, NULL, ARG_SILENT},
                {"kerneldir", required_argument, NULL, ARG_KERNELDIR},
                {"firmwaredirs", required_argument, NULL, ARG_FIRMWAREDIRS},
                {NULL, 0, NULL, 0}
        };

        while ((c = getopt_long(argc, argv, "madfhlL:oD:Hr:Rp:P:s:S:N:v", options, NULL)) != -1) {
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
                case ARG_SILENT:
                        arg_silent = true;
                        break;
                case ARG_MODALIAS:
                        arg_modalias = true;
                        return 1;
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
                case 'm':
                        arg_module = true;
                        break;
                case 'D':
                        destrootdir = optarg;
                        break;
                case 'r':
                        sysrootdir = optarg;
                        sysrootdirlen = strlen(sysrootdir);
                        break;
                case 'p':
                        if (regcomp(&mod_filter_path, optarg, REG_NOSUB | REG_EXTENDED) != 0) {
                                log_error("Module path filter %s is not a regular expression", optarg);
                                exit(EXIT_FAILURE);
                        }
                        arg_mod_filter_path = true;
                        break;
                case 'P':
                        if (regcomp(&mod_filter_nopath, optarg, REG_NOSUB | REG_EXTENDED) != 0) {
                                log_error("Module path filter %s is not a regular expression", optarg);
                                exit(EXIT_FAILURE);
                        }
                        arg_mod_filter_nopath = true;
                        break;
                case 's':
                        if (regcomp(&mod_filter_symbol, optarg, REG_NOSUB | REG_EXTENDED) != 0) {
                                log_error("Module symbol filter %s is not a regular expression", optarg);
                                exit(EXIT_FAILURE);
                        }
                        arg_mod_filter_symbol = true;
                        break;
                case 'S':
                        if (regcomp(&mod_filter_nosymbol, optarg, REG_NOSUB | REG_EXTENDED) != 0) {
                                log_error("Module symbol filter %s is not a regular expression", optarg);
                                exit(EXIT_FAILURE);
                        }
                        arg_mod_filter_nosymbol = true;
                        break;
                case 'N':
                        if (regcomp(&mod_filter_noname, optarg, REG_NOSUB | REG_EXTENDED) != 0) {
                                log_error("Module symbol filter %s is not a regular expression", optarg);
                                exit(EXIT_FAILURE);
                        }
                        arg_mod_filter_noname = true;
                        break;
                case 'L':
                        logdir = optarg;
                        break;
                case ARG_KERNELDIR:
                        kerneldir = optarg;
                        break;
                case ARG_FIRMWAREDIRS:
                        firmwaredirs = strv_split(optarg, ":");
                        break;
                case 'f':
                        arg_hmac = true;
                        break;
                case 'H':
                        arg_hostonly = true;
                        break;
                case 'h':
                        usage(EXIT_SUCCESS);
                        break;
                default:
                        usage(EXIT_FAILURE);
                }
        }

        if (arg_loglevel >= 0) {
                log_set_max_level(arg_loglevel);
        }

        struct utsname buf = {0};
        if (!kerneldir) {
                uname(&buf);
                _asprintf(&kerneldir, "/lib/modules/%s", buf.release);
        }

        if (arg_modalias) {
                return 1;
        }

        if (arg_module) {
                if (!firmwaredirs) {
                        char *path = getenv("DRACUT_FIRMWARE_PATH");

                        if (path) {
                                log_debug("DRACUT_FIRMWARE_PATH=%s", path);
                                firmwaredirs = strv_split(path, ":");
                        } else {
                                if (!*buf.release)
                                        uname(&buf);

                                char fw_path_para[PATH_MAX + 1] = "";
                                int path = open("/sys/module/firmware_class/parameters/path", O_RDONLY | O_CLOEXEC);
                                if (path != -1) {
                                        ssize_t rd = read(path, fw_path_para, PATH_MAX);
                                        if (rd != -1)
                                                fw_path_para[rd - 1] = '\0';
                                        close(path);
                                }
                                char uk[22 + sizeof(buf.release)], fk[14 + sizeof(buf.release)];
                                sprintf(uk, "/lib/firmware/updates/%s", buf.release);
                                sprintf(fk, "/lib/firmware/%s", buf.release);
                                firmwaredirs = strv_new(STRV_IFNOTNULL(*fw_path_para ? fw_path_para : NULL),
                                                        uk,
                                                        "/lib/firmware/updates",
                                                        fk,
                                                        "/lib/firmware",
                                                        NULL);
                        }
                }
        }

        if (!optind || optind == argc) {
                if (!arg_optional) {
                        log_error("No SOURCE argument given");
                        usage(EXIT_FAILURE);
                } else {
                        exit(EXIT_SUCCESS);
                }
        }

        return 1;
}

static int resolve_lazy(int argc, char **argv)
{
        int i;
        size_t destrootdirlen = strlen(destrootdir);
        int ret = 0;
        char *item;
        for (i = 0; i < argc; i++) {
                const char *src = argv[i];
                char *p = argv[i];

                log_debug("resolve_deps('%s')", src);

                if (strstr(src, destrootdir)) {
                        p = &argv[i][destrootdirlen];
                }

                if (check_hashmap(items, p)) {
                        continue;
                }

                item = strdup(p);
                hashmap_put(items, item, item);

                ret += resolve_deps(src);
        }
        return ret;
}

static char **find_binary(const char *src)
{
        char **ret = NULL;
        char **q;
        char *newsrc = NULL;

        STRV_FOREACH(q, pathdirs) {
                char *fullsrcpath;

                _asprintf(&newsrc, "%s/%s", *q, src);

                fullsrcpath = get_real_file(newsrc, false);
                if (!fullsrcpath) {
                        log_debug("get_real_file(%s) not found", newsrc);
                        free(newsrc);
                        newsrc = NULL;
                        continue;
                }

                if (faccessat(AT_FDCWD, fullsrcpath, F_OK, AT_SYMLINK_NOFOLLOW) != 0) {
                        log_debug("lstat(%s) != 0", fullsrcpath);
                        free(newsrc);
                        newsrc = NULL;
                        free(fullsrcpath);
                        fullsrcpath = NULL;
                        continue;
                }

                strv_push(&ret, newsrc);

                free(fullsrcpath);
                fullsrcpath = NULL;
        };

        if (ret) {
                STRV_FOREACH(q, ret) {
                        log_debug("find_binary(%s) == %s", src, *q);
                }
        }

        return ret;
}

static int install_one(const char *src, const char *dst)
{
        int r = EXIT_SUCCESS;
        int ret = 0;

        if (strchr(src, '/') == NULL) {
                char **p = find_binary(src);
                if (p) {
                        char **q = NULL;
                        STRV_FOREACH(q, p) {
                                char *newsrc = *q;
                                log_debug("dracut_install '%s' '%s'", newsrc, dst);
                                ret = dracut_install(newsrc, dst, arg_createdir, arg_resolvedeps, true);
                                if (ret == 0) {
                                        log_debug("dracut_install '%s' '%s' OK", newsrc, dst);
                                }
                        }
                        strv_free(p);
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
        int r = EXIT_SUCCESS;
        int i;
        for (i = 0; i < argc; i++) {
                int ret = 0;
                log_debug("Handle '%s'", argv[i]);

                if (strchr(argv[i], '/') == NULL) {
                        char **p = find_binary(argv[i]);
                        if (p) {
                                char **q = NULL;
                                STRV_FOREACH(q, p) {
                                        char *newsrc = *q;
                                        log_debug("dracut_install '%s'", newsrc);
                                        ret = dracut_install(newsrc, newsrc, arg_createdir, arg_resolvedeps, true);
                                        if (ret == 0) {
                                                log_debug("dracut_install '%s' OK", newsrc);
                                        }
                                }
                                strv_free(p);
                        } else {
                                ret = -1;
                        }

                } else {
                        if (strchr(argv[i], '*') == NULL) {
                                ret = dracut_install(argv[i], argv[i], arg_createdir, arg_resolvedeps, true);
                        } else {
                                _cleanup_free_ char *realsrc = NULL;
                                _cleanup_globfree_ glob_t globbuf;

                                _asprintf(&realsrc, "%s%s", sysrootdir ? sysrootdir : "", argv[i]);

                                ret = glob(realsrc, 0, NULL, &globbuf);
                                if (ret == 0) {
                                        size_t j;

                                        for (j = 0; j < globbuf.gl_pathc; j++) {
                                                ret |= dracut_install(globbuf.gl_pathv[j] + sysrootdirlen,
                                                                      globbuf.gl_pathv[j] + sysrootdirlen,
                                                                      arg_createdir, arg_resolvedeps, true);
                                        }
                                }
                        }
                }

                if ((ret != 0) && (!arg_optional)) {
                        log_error("ERROR: installing '%s'", argv[i]);
                        r = EXIT_FAILURE;
                }
        }
        return r;
}

static int install_firmware_fullpath(const char *fwpath)
{
        const char *fw = fwpath;
        _cleanup_free_ char *fwpath_compressed = NULL;
        int ret;
        if (access(fwpath, F_OK) != 0) {
                _asprintf(&fwpath_compressed, "%s.zst", fwpath);
                if (access(fwpath_compressed, F_OK) != 0) {
                        strcpy(fwpath_compressed + strlen(fwpath) + 1, "xz");
                        if (access(fwpath_compressed, F_OK) != 0) {
                                log_debug("stat(%s) != 0", fwpath);
                                return 1;
                        }
                }
                fw = fwpath_compressed;
        }
        ret = dracut_install(fw, fw, false, false, true);
        if (ret == 0) {
                log_debug("dracut_install '%s' OK", fwpath);
        }
        return ret;
}

static int install_firmware(struct kmod_module *mod)
{
        struct kmod_list *l = NULL;
        _cleanup_kmod_module_info_free_list_ struct kmod_list *list = NULL;
        int ret;
        char **q;

        ret = kmod_module_get_info(mod, &list);
        if (ret < 0) {
                log_error("could not get modinfo from '%s': %s\n", kmod_module_get_name(mod), strerror(-ret));
                return ret;
        }
        kmod_list_foreach(l, list) {
                const char *key = kmod_module_info_get_key(l);
                const char *value = NULL;
                bool found_this = false;

                if (!streq("firmware", key))
                        continue;

                value = kmod_module_info_get_value(l);
                log_debug("Firmware %s", value);
                ret = -1;
                STRV_FOREACH(q, firmwaredirs) {
                        _cleanup_free_ char *fwpath = NULL;

                        _asprintf(&fwpath, "%s/%s", *q, value);

                        if (strpbrk(value, "*?[") != NULL
                            && access(fwpath, F_OK) != 0) {
                                size_t i;
                                _cleanup_globfree_ glob_t globbuf;

                                glob(fwpath, 0, NULL, &globbuf);
                                for (i = 0; i < globbuf.gl_pathc; i++) {
                                        ret = install_firmware_fullpath(globbuf.gl_pathv[i]);
                                        if (ret == 0)
                                                found_this = true;
                                }
                        } else {
                                ret = install_firmware_fullpath(fwpath);
                                if (ret == 0)
                                        found_this = true;
                        }
                }
                if (!found_this) {
                        /* firmware path was not found in any firmwaredirs */
                        log_info("Missing firmware %s for kernel module %s",
                                 value, kmod_module_get_name(mod));
                }
        }
        return 0;
}

static bool check_module_symbols(struct kmod_module *mod)
{
        struct kmod_list *itr = NULL;
        _cleanup_kmod_module_dependency_symbols_free_list_ struct kmod_list *deplist = NULL;

        if (!arg_mod_filter_symbol && !arg_mod_filter_nosymbol)
                return true;

        if (kmod_module_get_dependency_symbols(mod, &deplist) < 0) {
                log_debug("kmod_module_get_dependency_symbols failed");
                if (arg_mod_filter_symbol)
                        return false;
                return true;
        }

        if (arg_mod_filter_nosymbol) {
                kmod_list_foreach(itr, deplist) {
                        const char *symbol = kmod_module_symbol_get_symbol(itr);
                        // log_debug("Checking symbol %s", symbol);
                        if (regexec(&mod_filter_nosymbol, symbol, 0, NULL, 0) == 0) {
                                log_debug("Module %s: symbol %s matched exclusion filter", kmod_module_get_name(mod),
                                          symbol);
                                return false;
                        }
                }
        }

        if (arg_mod_filter_symbol) {
                kmod_list_foreach(itr, deplist) {
                        const char *symbol = kmod_module_dependency_symbol_get_symbol(itr);
                        // log_debug("Checking symbol %s", symbol);
                        if (regexec(&mod_filter_symbol, symbol, 0, NULL, 0) == 0) {
                                log_debug("Module %s: symbol %s matched inclusion filter", kmod_module_get_name(mod),
                                          symbol);
                                return true;
                        }
                }
                return false;
        }

        return true;
}

static bool check_module_path(const char *path)
{
        if (arg_mod_filter_nopath && (regexec(&mod_filter_nopath, path, 0, NULL, 0) == 0)) {
                log_debug("Path %s matched exclusion filter", path);
                return false;
        }

        if (arg_mod_filter_path && (regexec(&mod_filter_path, path, 0, NULL, 0) != 0)) {
                log_debug("Path %s matched inclusion filter", path);
                return false;
        }
        return true;
}

static int find_kmod_module_from_sysfs_node(struct kmod_ctx *ctx, const char *sysfs_node, int sysfs_node_len,
                                            struct kmod_list **modules)
{
        char modalias_path[PATH_MAX];
        if (snprintf(modalias_path, sizeof(modalias_path), "%.*s/modalias", sysfs_node_len,
                     sysfs_node) >= sizeof(modalias_path))
                return -1;

        _cleanup_close_ int modalias_file = -1;
        if ((modalias_file = open(modalias_path, O_RDONLY | O_CLOEXEC)) == -1)
                return 0;

        char alias[page_size()];
        ssize_t len = read(modalias_file, alias, sizeof(alias));
        alias[len - 1] = '\0';

        return kmod_module_new_from_lookup(ctx, alias, modules);
}

static int find_modules_from_sysfs_node(struct kmod_ctx *ctx, const char *sysfs_node, Hashmap *modules)
{
        _cleanup_kmod_module_unref_list_ struct kmod_list *list = NULL;
        struct kmod_list *l = NULL;

        if (find_kmod_module_from_sysfs_node(ctx, sysfs_node, strlen(sysfs_node), &list) >= 0) {
                kmod_list_foreach(l, list) {
                        struct kmod_module *mod = kmod_module_get_module(l);
                        char *module = strdup(kmod_module_get_name(mod));
                        kmod_module_unref(mod);

                        if (hashmap_put(modules, module, module) < 0)
                                free(module);
                }
        }

        return 0;
}

static void find_suppliers_for_sys_node(struct kmod_ctx *ctx, Hashmap *suppliers, const char *node_path_raw,
                                        size_t node_path_len)
{
        char node_path[PATH_MAX];
        char real_path[PATH_MAX];

        memcpy(node_path, node_path_raw, node_path_len);
        node_path[node_path_len] = '\0';

        DIR *d;
        struct dirent *dir;
        while (realpath(node_path, real_path) != NULL && strcmp(real_path, "/sys/devices")) {
                d = opendir(node_path);
                if (d) {
                        size_t real_path_len = strlen(real_path);
                        while ((dir = readdir(d)) != NULL) {
                                if (strstr(dir->d_name, "supplier:platform") != NULL) {
                                        if (snprintf(real_path + real_path_len, sizeof(real_path) - real_path_len, "/%s/supplier",
                                                     dir->d_name) < sizeof(real_path) - real_path_len) {
                                                char *real_supplier_path = realpath(real_path, NULL);
                                                if (real_supplier_path != NULL)
                                                        if (hashmap_put(suppliers, real_supplier_path, real_supplier_path) < 0)
                                                                free(real_supplier_path);
                                        }
                                }
                        }
                        closedir(d);
                }
                strncat(node_path, "/..", 3); // Also find suppliers of parents
        }
}

static void find_suppliers(struct kmod_ctx *ctx)
{
        _cleanup_fts_close_ FTS *fts;
        char *paths[] = { "/sys/devices/platform", NULL };
        fts = fts_open(paths, FTS_NOSTAT | FTS_PHYSICAL, NULL);

        for (FTSENT *ftsent = fts_read(fts); ftsent != NULL; ftsent = fts_read(fts)) {
                if (strcmp(ftsent->fts_name, "modalias") == 0) {
                        _cleanup_kmod_module_unref_list_ struct kmod_list *list = NULL;
                        struct kmod_list *l;

                        if (find_kmod_module_from_sysfs_node(ctx, ftsent->fts_parent->fts_path, ftsent->fts_parent->fts_pathlen, &list) < 0)
                                continue;

                        kmod_list_foreach(l, list) {
                                _cleanup_kmod_module_unref_ struct kmod_module *mod = kmod_module_get_module(l);
                                const char *name = kmod_module_get_name(mod);
                                Hashmap *suppliers = hashmap_get(modules_suppliers, name);
                                if (suppliers == NULL) {
                                        suppliers = hashmap_new(string_hash_func, string_compare_func);
                                        hashmap_put(modules_suppliers, strdup(name), suppliers);
                                }

                                find_suppliers_for_sys_node(ctx, suppliers, ftsent->fts_parent->fts_path, ftsent->fts_parent->fts_pathlen);
                        }
                }
        }
}

static Hashmap *find_suppliers_paths_for_module(const char *module)
{
        return hashmap_get(modules_suppliers, module);
}

static int install_dependent_module(struct kmod_ctx *ctx, struct kmod_module *mod, Hashmap *suppliers_paths, int *err)
{
        const char *path = NULL;
        const char *name = NULL;

        path = kmod_module_get_path(mod);

        if (path == NULL)
                return 0;

        if (check_hashmap(items_failed, path))
                return -1;

        if (check_hashmap(items, &path[kerneldirlen])) {
                return 0;
        }

        name = kmod_module_get_name(mod);

        if (arg_mod_filter_noname && (regexec(&mod_filter_noname, name, 0, NULL, 0) == 0)) {
                return 0;
        }

        *err = dracut_install(path, &path[kerneldirlen], false, false, true);
        if (*err == 0) {
                _cleanup_kmod_module_unref_list_ struct kmod_list *modlist = NULL;
                _cleanup_kmod_module_unref_list_ struct kmod_list *modpre = NULL;
                _cleanup_kmod_module_unref_list_ struct kmod_list *modpost = NULL;
                log_debug("dracut_install '%s' '%s' OK", path, &path[kerneldirlen]);
                install_firmware(mod);
                modlist = kmod_module_get_dependencies(mod);
                *err = install_dependent_modules(ctx, modlist, suppliers_paths);
                if (*err == 0) {
                        *err = kmod_module_get_softdeps(mod, &modpre, &modpost);
                        if (*err == 0) {
                                int r;
                                *err = install_dependent_modules(ctx, modpre, NULL);
                                r = install_dependent_modules(ctx, modpost, NULL);
                                *err = *err ? : r;
                        }
                }
        } else {
                log_error("dracut_install '%s' '%s' ERROR", path, &path[kerneldirlen]);
        }

        return 0;
}

static int install_dependent_modules(struct kmod_ctx *ctx, struct kmod_list *modlist, Hashmap *suppliers_paths)
{
        struct kmod_list *itr = NULL;
        int ret = 0;

        kmod_list_foreach(itr, modlist) {
                _cleanup_kmod_module_unref_ struct kmod_module *mod = NULL;
                mod = kmod_module_get_module(itr);
                if (install_dependent_module(ctx, mod, find_suppliers_paths_for_module(kmod_module_get_name(mod)), &ret))
                        return -1;
        }

        const char *supplier_path;
        Iterator i;
        HASHMAP_FOREACH(supplier_path, suppliers_paths, i) {
                if (check_hashmap(processed_suppliers, supplier_path))
                        continue;

                char *path = strdup(supplier_path);
                hashmap_put(processed_suppliers, path, path);

                _cleanup_destroy_hashmap_ Hashmap *modules = hashmap_new(string_hash_func, string_compare_func);
                find_modules_from_sysfs_node(ctx, supplier_path, modules);

                _cleanup_destroy_hashmap_ Hashmap *suppliers = hashmap_new(string_hash_func, string_compare_func);
                find_suppliers_for_sys_node(ctx, suppliers, supplier_path, strlen(supplier_path));

                if (!hashmap_isempty(modules)) { // Supplier is a module
                        const char *module;
                        Iterator j;
                        HASHMAP_FOREACH(module, modules, j) {
                                _cleanup_kmod_module_unref_ struct kmod_module *mod = NULL;
                                if (!kmod_module_new_from_name(ctx, module, &mod)) {
                                        if (install_dependent_module(ctx, mod, suppliers, &ret))
                                                return -1;
                                }
                        }
                } else { // Supplier is builtin
                        install_dependent_modules(ctx, NULL, suppliers);
                }
        }

        return ret;
}

static int install_module(struct kmod_ctx *ctx, struct kmod_module *mod)
{
        int ret = 0;
        _cleanup_kmod_module_unref_list_ struct kmod_list *modlist = NULL;
        _cleanup_kmod_module_unref_list_ struct kmod_list *modpre = NULL;
        _cleanup_kmod_module_unref_list_ struct kmod_list *modpost = NULL;
        const char *path = NULL;
        const char *name = NULL;

        name = kmod_module_get_name(mod);

        path = kmod_module_get_path(mod);
        if (!path) {
                log_debug("dracut_install '%s' is a builtin kernel module", name);
                return 0;
        }

        if (arg_mod_filter_noname && (regexec(&mod_filter_noname, name, 0, NULL, 0) == 0)) {
                log_debug("dracut_install '%s' is excluded", name);
                return 0;
        }

        if (arg_hostonly && !check_hashmap(modules_loaded, name)) {
                log_debug("dracut_install '%s' not hostonly", name);
                return 0;
        }

        if (check_hashmap(items_failed, path))
                return -1;

        if (check_hashmap(items, path))
                return 0;

        if (!check_module_path(path) || !check_module_symbols(mod)) {
                log_debug("No symbol or path match for '%s'", path);
                return 1;
        }

        log_debug("dracut_install '%s' '%s'", path, &path[kerneldirlen]);

        ret = dracut_install(path, &path[kerneldirlen], false, false, true);
        if (ret == 0) {
                log_debug("dracut_install '%s' OK", kmod_module_get_name(mod));
        } else if (!arg_optional) {
                if (!arg_silent)
                        log_error("dracut_install '%s' ERROR", kmod_module_get_name(mod));
                return ret;
        }
        install_firmware(mod);

        Hashmap *suppliers = find_suppliers_paths_for_module(name);
        modlist = kmod_module_get_dependencies(mod);
        ret = install_dependent_modules(ctx, modlist, suppliers);

        if (ret == 0) {
                ret = kmod_module_get_softdeps(mod, &modpre, &modpost);
                if (ret == 0) {
                        int r;
                        ret = install_dependent_modules(ctx, modpre, NULL);
                        r = install_dependent_modules(ctx, modpost, NULL);
                        ret = ret ? : r;
                }
        }

        return ret;
}

static int modalias_list(struct kmod_ctx *ctx)
{
        int err;
        struct kmod_list *loaded_list = NULL;
        struct kmod_list *l = NULL;
        struct kmod_list *itr = NULL;
        _cleanup_fts_close_ FTS *fts = NULL;

        {
                char *paths[] = { "/sys/devices", NULL };
                fts = fts_open(paths, FTS_NOCHDIR | FTS_NOSTAT, NULL);
        }
        for (FTSENT *ftsent = fts_read(fts); ftsent != NULL; ftsent = fts_read(fts)) {
                _cleanup_fclose_ FILE *f = NULL;
                _cleanup_kmod_module_unref_list_ struct kmod_list *list = NULL;

                int err;

                char alias[2048] = {0};
                size_t len;

                if (strncmp("modalias", ftsent->fts_name, 8) != 0)
                        continue;
                if (!(f = fopen(ftsent->fts_accpath, "r")))
                        continue;

                if (!fgets(alias, sizeof(alias), f))
                        continue;

                len = strlen(alias);

                if (len == 0)
                        continue;

                if (alias[len - 1] == '\n')
                        alias[len - 1] = 0;

                err = kmod_module_new_from_lookup(ctx, alias, &list);
                if (err < 0)
                        continue;

                kmod_list_foreach(l, list) {
                        struct kmod_module *mod = kmod_module_get_module(l);
                        char *name = strdup(kmod_module_get_name(mod));
                        kmod_module_unref(mod);
                        hashmap_put(modules_loaded, name, name);
                }
        }

        err = kmod_module_new_from_loaded(ctx, &loaded_list);
        if (err < 0) {
                errno = err;
                log_error("Could not get list of loaded modules: %m. Switching to non-hostonly mode.");
                arg_hostonly = false;
        } else {
                kmod_list_foreach(itr, loaded_list) {
                        _cleanup_kmod_module_unref_list_ struct kmod_list *modlist = NULL;

                        struct kmod_module *mod = kmod_module_get_module(itr);
                        char *name = strdup(kmod_module_get_name(mod));
                        hashmap_put(modules_loaded, name, name);
                        kmod_module_unref(mod);

                        /* also put the modules from the new kernel in the hashmap,
                         * which resolve the name as an alias, in case a kernel module is
                         * renamed.
                         */
                        err = kmod_module_new_from_lookup(ctx, name, &modlist);
                        if (err < 0)
                                continue;
                        if (!modlist)
                                continue;
                        kmod_list_foreach(l, modlist) {
                                mod = kmod_module_get_module(l);
                                char *name = strdup(kmod_module_get_name(mod));
                                hashmap_put(modules_loaded, name, name);
                                kmod_module_unref(mod);
                        }
                }
                kmod_module_unref_list(loaded_list);
        }
        return 0;
}

static int install_modules(int argc, char **argv)
{
        _cleanup_kmod_unref_ struct kmod_ctx *ctx = NULL;
        struct kmod_list *itr = NULL;

        struct kmod_module *mod = NULL, *mod_o = NULL;

        const char *abskpath = NULL;
        char *p;
        int i;
        int modinst = 0;

        ctx = kmod_new(kerneldir, NULL);
        abskpath = kmod_get_dirname(ctx);

        p = strstr(abskpath, "/lib/modules/");
        if (p != NULL)
                kerneldirlen = p - abskpath;

        modules_suppliers = hashmap_new(string_hash_func, string_compare_func);
        find_suppliers(ctx);

        if (arg_hostonly) {
                char *modalias_file;
                modalias_file = getenv("DRACUT_KERNEL_MODALIASES");

                if (modalias_file == NULL) {
                        modalias_list(ctx);
                } else {
                        _cleanup_fclose_ FILE *f = NULL;
                        if ((f = fopen(modalias_file, "r"))) {
                                char name[2048];

                                while (!feof(f)) {
                                        size_t len;
                                        char *dupname = NULL;

                                        if (!(fgets(name, sizeof(name), f)))
                                                continue;
                                        len = strlen(name);

                                        if (len == 0)
                                                continue;

                                        if (name[len - 1] == '\n')
                                                name[len - 1] = 0;

                                        log_debug("Adding module '%s' to hostonly module list", name);
                                        dupname = strdup(name);
                                        hashmap_put(modules_loaded, dupname, dupname);
                                }
                        }
                }

        }

        for (i = 0; i < argc; i++) {
                int r = 0;
                int ret = -1;
                log_debug("Handle module '%s'", argv[i]);

                if (argv[i][0] == '/') {
                        _cleanup_kmod_module_unref_list_ struct kmod_list *modlist = NULL;
                        _cleanup_free_ const char *modname = NULL;

                        r = kmod_module_new_from_path(ctx, argv[i], &mod_o);
                        if (r < 0) {
                                log_debug("Failed to lookup modules path '%s': %m", argv[i]);
                                if (!arg_optional)
                                        return -ENOENT;
                                continue;
                        }
                        /* Check, if we have to load another module with that name instead */
                        modname = strdup(kmod_module_get_name(mod_o));

                        if (!modname) {
                                if (!arg_optional) {
                                        if (!arg_silent)
                                                log_error("Failed to get name for module '%s'", argv[i]);
                                        return -ENOENT;
                                }
                                log_info("Failed to get name for module '%s'", argv[i]);
                                continue;
                        }

                        r = kmod_module_new_from_lookup(ctx, modname, &modlist);
                        kmod_module_unref(mod_o);
                        mod_o = NULL;

                        if (r < 0) {
                                if (!arg_optional) {
                                        if (!arg_silent)
                                                log_error("3 Failed to lookup alias '%s': %d", modname, r);
                                        return -ENOENT;
                                }
                                log_info("3 Failed to lookup alias '%s': %d", modname, r);
                                continue;
                        }
                        if (!modlist) {
                                if (!arg_optional) {
                                        if (!arg_silent)
                                                log_error("Failed to find module '%s' %s", modname, argv[i]);
                                        return -ENOENT;
                                }
                                log_info("Failed to find module '%s' %s", modname, argv[i]);
                                continue;
                        }
                        kmod_list_foreach(itr, modlist) {
                                mod = kmod_module_get_module(itr);
                                r = install_module(ctx, mod);
                                kmod_module_unref(mod);
                                if ((r < 0) && !arg_optional) {
                                        if (!arg_silent)
                                                log_error("ERROR: installing module '%s'", modname);
                                        return -ENOENT;
                                };
                                ret = (ret == 0 ? 0 : r);
                                modinst = 1;
                        }
                } else if (argv[i][0] == '=') {
                        _cleanup_free_ char *path1 = NULL, *path2 = NULL, *path3 = NULL;
                        _cleanup_fts_close_ FTS *fts = NULL;

                        log_debug("Handling =%s", &argv[i][1]);
                        /* FIXME and add more paths */
                        _asprintf(&path2, "%s/kernel/%s", kerneldir, &argv[i][1]);
                        _asprintf(&path1, "%s/extra/%s", kerneldir, &argv[i][1]);
                        _asprintf(&path3, "%s/updates/%s", kerneldir, &argv[i][1]);

                        {
                                char *paths[] = { path1, path2, path3, NULL };
                                fts = fts_open(paths, FTS_COMFOLLOW | FTS_NOCHDIR | FTS_NOSTAT | FTS_LOGICAL, NULL);
                        }

                        for (FTSENT *ftsent = fts_read(fts); ftsent != NULL; ftsent = fts_read(fts)) {
                                _cleanup_kmod_module_unref_list_ struct kmod_list *modlist = NULL;
                                _cleanup_free_ const char *modname = NULL;

                                if ((ftsent->fts_info == FTS_D) && !check_module_path(ftsent->fts_accpath)) {
                                        fts_set(fts, ftsent, FTS_SKIP);
                                        log_debug("Skipping %s", ftsent->fts_accpath);
                                        continue;
                                }
                                if ((ftsent->fts_info != FTS_F) && (ftsent->fts_info != FTS_SL)) {
                                        log_debug("Ignoring %s", ftsent->fts_accpath);
                                        continue;
                                }
                                log_debug("Handling %s", ftsent->fts_accpath);
                                r = kmod_module_new_from_path(ctx, ftsent->fts_accpath, &mod_o);
                                if (r < 0) {
                                        log_debug("Failed to lookup modules path '%s': %m", ftsent->fts_accpath);
                                        if (!arg_optional) {
                                                return -ENOENT;
                                        }
                                        continue;
                                }

                                /* Check, if we have to load another module with that name instead */
                                modname = strdup(kmod_module_get_name(mod_o));

                                if (!modname) {
                                        log_error("Failed to get name for module '%s'", ftsent->fts_accpath);
                                        if (!arg_optional) {
                                                return -ENOENT;
                                        }
                                        continue;
                                }
                                r = kmod_module_new_from_lookup(ctx, modname, &modlist);
                                kmod_module_unref(mod_o);
                                mod_o = NULL;

                                if (r < 0) {
                                        log_error("Failed to lookup alias '%s': %m", modname);
                                        if (!arg_optional) {
                                                return -ENOENT;
                                        }
                                        continue;
                                }

                                if (!modlist) {
                                        log_error("Failed to find module '%s' %s", modname, ftsent->fts_accpath);
                                        if (!arg_optional) {
                                                return -ENOENT;
                                        }
                                        continue;
                                }
                                kmod_list_foreach(itr, modlist) {
                                        mod = kmod_module_get_module(itr);
                                        r = install_module(ctx, mod);
                                        kmod_module_unref(mod);
                                        if ((r < 0) && !arg_optional) {
                                                if (!arg_silent)
                                                        log_error("ERROR: installing module '%s'", modname);
                                                return -ENOENT;
                                        };
                                        ret = (ret == 0 ? 0 : r);
                                        modinst = 1;
                                }
                        }
                        if (errno) {
                                log_error("FTS ERROR: %m");
                        }
                } else {
                        _cleanup_kmod_module_unref_list_ struct kmod_list *modlist = NULL;
                        char *modname = argv[i];

                        if (endswith(modname, ".ko")) {
                                int len = strlen(modname);
                                modname[len - 3] = 0;
                        }
                        if (endswith(modname, ".ko.xz") || endswith(modname, ".ko.gz")) {
                                int len = strlen(modname);
                                modname[len - 6] = 0;
                        }
                        if (endswith(modname, ".ko.zst")) {
                                int len = strlen(modname);
                                modname[len - 7] = 0;
                        }
                        r = kmod_module_new_from_lookup(ctx, modname, &modlist);
                        if (r < 0) {
                                if (!arg_optional) {
                                        if (!arg_silent)
                                                log_error("Failed to lookup alias '%s': %m", modname);
                                        return -ENOENT;
                                }
                                log_info("Failed to lookup alias '%s': %m", modname);
                                continue;
                        }
                        if (!modlist) {
                                if (!arg_optional) {
                                        if (!arg_silent)
                                                log_error("Failed to find module '%s'", modname);
                                        return -ENOENT;
                                }
                                log_info("Failed to find module '%s'", modname);
                                continue;
                        }
                        kmod_list_foreach(itr, modlist) {
                                mod = kmod_module_get_module(itr);
                                r = install_module(ctx, mod);
                                kmod_module_unref(mod);
                                if ((r < 0) && !arg_optional) {
                                        if (!arg_silent)
                                                log_error("ERROR: installing '%s'", argv[i]);
                                        return -ENOENT;
                                };
                                ret = (ret == 0 ? 0 : r);
                                modinst = 1;
                        }
                }

                if ((modinst != 0) && (ret != 0) && (!arg_optional)) {
                        if (!arg_silent)
                                log_error("ERROR: installing '%s'", argv[i]);
                        return EXIT_FAILURE;
                }
        }

        return EXIT_SUCCESS;
}

int main(int argc, char **argv)
{
        int r;
        char *i;
        char *path = NULL;
        char *env_no_xattr = NULL;

        log_set_target(LOG_TARGET_CONSOLE);
        log_parse_environment();
        log_open();

        r = parse_argv(argc, argv);
        if (r <= 0)
                return r < 0 ? EXIT_FAILURE : EXIT_SUCCESS;

        modules_loaded = hashmap_new(string_hash_func, string_compare_func);
        if (arg_modalias) {
                Iterator i;
                char *name;
                _cleanup_kmod_unref_ struct kmod_ctx *ctx = NULL;
                ctx = kmod_new(kerneldir, NULL);

                modalias_list(ctx);
                HASHMAP_FOREACH(name, modules_loaded, i) {
                        printf("%s\n", name);
                }
                exit(0);
        }

        log_debug("Program arguments:");
        for (r = 0; r < argc; r++)
                log_debug("%s", argv[r]);

        path = getenv("DRACUT_INSTALL_PATH");
        if (path == NULL)
                path = getenv("PATH");

        if (path == NULL) {
                log_error("PATH is not set");
                exit(EXIT_FAILURE);
        }

        log_debug("PATH=%s", path);

        ldd = getenv("DRACUT_LDD");
        if (ldd == NULL)
                ldd = "ldd";
        log_debug("LDD=%s", ldd);

        env_no_xattr = getenv("DRACUT_NO_XATTR");
        if (env_no_xattr != NULL)
                no_xattr = true;

        pathdirs = strv_split(path, ":");

        umask(0022);

        if (destrootdir == NULL || strlen(destrootdir) == 0) {
                destrootdir = getenv("DESTROOTDIR");
                if (destrootdir == NULL || strlen(destrootdir) == 0) {
                        log_error("Environment DESTROOTDIR or argument -D is not set!");
                        usage(EXIT_FAILURE);
                }
        }

        if (strcmp(destrootdir, "/") == 0) {
                log_error("Environment DESTROOTDIR or argument -D is set to '/'!");
                usage(EXIT_FAILURE);
        }

        i = destrootdir;
        if (!(destrootdir = realpath(i, NULL))) {
                log_error("Environment DESTROOTDIR or argument -D is set to '%s': %m", i);
                r = EXIT_FAILURE;
                goto finish2;
        }

        items = hashmap_new(string_hash_func, string_compare_func);
        items_failed = hashmap_new(string_hash_func, string_compare_func);
        processed_suppliers = hashmap_new(string_hash_func, string_compare_func);

        if (!items || !items_failed || !processed_suppliers || !modules_loaded) {
                log_error("Out of memory");
                r = EXIT_FAILURE;
                goto finish1;
        }

        if (logdir) {
                _asprintf(&logfile, "%s/%d.log", logdir, getpid());

                logfile_f = fopen(logfile, "a");
                if (logfile_f == NULL) {
                        log_error("Could not open %s for logging: %m", logfile);
                        r = EXIT_FAILURE;
                        goto finish1;
                }
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

        if (arg_module) {
                r = install_modules(argc - optind, &argv[optind]);
        } else if (arg_resolvelazy) {
                r = resolve_lazy(argc - optind, &argv[optind]);
        } else if (arg_all || (argc - optind > 2) || ((argc - optind) == 1)) {
                r = install_all(argc - optind, &argv[optind]);
        } else {
                /* simple "inst src dst" */
                r = install_one(argv[optind], argv[optind + 1]);
        }

        if (arg_optional)
                r = EXIT_SUCCESS;

finish1:
        free(destrootdir);
finish2:
        if (logfile_f)
                fclose(logfile_f);

        while ((i = hashmap_steal_first(modules_loaded)))
                item_free(i);

        while ((i = hashmap_steal_first(items)))
                item_free(i);

        while ((i = hashmap_steal_first(items_failed)))
                item_free(i);

        Hashmap *h;
        while ((h = hashmap_steal_first(modules_suppliers))) {
                while ((i = hashmap_steal_first(h))) {
                        item_free(i);
                }
                hashmap_free(h);
        }

        while ((i = hashmap_steal_first(processed_suppliers)))
                item_free(i);

        hashmap_free(items);
        hashmap_free(items_failed);
        hashmap_free(modules_loaded);
        hashmap_free(modules_suppliers);
        hashmap_free(processed_suppliers);

        strv_free(firmwaredirs);
        strv_free(pathdirs);
        return r;
}
