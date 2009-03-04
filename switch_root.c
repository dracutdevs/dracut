/*
 * switch_root.c
 *
 * Code to switch from initramfs to system root.
 * Based on nash.c from mkinitrd
 *
 * Copyright 2002-2009 Red Hat, Inc.  All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Author(s): Erik Troan <ewt@redhat.com>
 *            Jeremy Katz <katzj@redhat.com>
 *            Peter Jones <pjones@redhat.com>
 *            Harald Hoyer <harald@redhat.com>
 */

#define _GNU_SOURCE 1
#include <sys/mount.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <stdio.h>
#include <dirent.h>
#include <alloca.h>
#include <string.h>
#include <errno.h>
#include <mntent.h>
#include <stdlib.h>
#include <ctype.h>
#include <sys/mount.h>
#include <fcntl.h>
#include <linux/fs.h>

#ifndef MNT_FORCE
#define MNT_FORCE 0x1
#endif

#ifndef MNT_DETACH
#define MNT_DETACH 0x2
#endif


#define asprintfa(str, fmt, ...) ({                 \
        char *_tmp = NULL;                          \
        int _rc;                                    \
        _rc = asprintf((str), (fmt), __VA_ARGS__);  \
        if (_rc != -1) {                            \
            _tmp = strdupa(*(str));                 \
            if (!_tmp) {                            \
                _rc = -1;                           \
            } else {                                \
                free(*(str));                       \
                *(str) = _tmp;                      \
            }                                       \
        }                                           \
        _rc;                                        \
    })



static inline int
setFdCoe(int fd, int enable)
{
    int rc;
    long flags = 0;

    rc = fcntl(fd, F_GETFD, &flags);
    if (rc < 0)
        return rc;

    if (enable)
        flags |= FD_CLOEXEC;
    else
        flags &= ~FD_CLOEXEC;

    rc = fcntl(fd, F_SETFD, flags);
    return rc;
}

static char *
getArg(char * cmd, char * end, char ** arg)
{
    char quote = '\0';

    if (!cmd || cmd >= end)
        return NULL;

    while (isspace(*cmd) && cmd < end)
        cmd++;
    if (cmd >= end)
        return NULL;

    if (*cmd == '"')
        cmd++, quote = '"';
    else if (*cmd == '\'')
        cmd++, quote = '\'';

    if (quote) {
        *arg = cmd;

        /* This doesn't support \ escapes */
        while (cmd < end && *cmd != quote)
            cmd++;

        if (cmd == end) {
            printf("error: quote mismatch for %s\n", *arg);
            return NULL;
        }

        *cmd = '\0';
        cmd++;
    } else {
        *arg = cmd;
        while (!isspace(*cmd) && cmd < end)
            cmd++;
        *cmd = '\0';
        if (**arg == '$')
            *arg = getenv(*arg+1);
        if (*arg == NULL)
            *arg = "";
    }

    cmd++;

    while (isspace(*cmd))
        cmd++;

    return cmd;
}

static int
mountCommand(char * cmd, char * end)
{
    char * fsType = NULL;
    char * device, *spec;
    char * mntPoint;
    char * opts = NULL;
    int rc = 0;
    int flags = MS_MGC_VAL;
    char * newOpts;

    if (!(cmd = getArg(cmd, end, &spec))) {
        printf(
            "usage: mount [--ro] [-o <opts>] -t <type> <device> <mntpoint>\n");
        return 1;
    }

    while (cmd && *spec == '-') {
        if (!strcmp(spec, "--ro")) {
            flags |= MS_RDONLY;
        } else if (!strcmp(spec, "--bind")) {
            flags = MS_BIND;
            fsType = "none";
        } else if (!strcmp(spec, "--move")) {
            flags = MS_MOVE;
            fsType = "none";
        } else if (!strcmp(spec, "-o")) {
            cmd = getArg(cmd, end, &opts);
            if (!cmd) {
                printf("mount: -o requires arguments\n");
                return 1;
            }
        } else if (!strcmp(spec, "-t")) {
            if (!(cmd = getArg(cmd, end, &fsType))) {
                printf("mount: missing filesystem type\n");
                return 1;
            }
        }

        cmd = getArg(cmd, end, &spec);
    }

    if (!cmd) {
        printf("mount: missing device or mountpoint\n");
        return 1;
    }

    if (!(cmd = getArg(cmd, end, &mntPoint))) {
        struct mntent *mnt;
        FILE *fstab;

        fstab = fopen("/etc/fstab", "r");
        if (!fstab) {
            printf("mount: missing mount point\n");
            return 1;
        }
        do {
            if (!(mnt = getmntent(fstab))) {
                printf("mount: missing mount point\n");
                fclose(fstab);
                return 1;
            }
            if (!strcmp(mnt->mnt_dir, spec)) {
                spec = mnt->mnt_fsname;
                mntPoint = mnt->mnt_dir;

                if (!strcmp(mnt->mnt_type, "bind")) {
                    flags |= MS_BIND;
                    fsType = "none";
                } else
                    fsType = mnt->mnt_type;

                opts = mnt->mnt_opts;
                break;
            }
        } while(1);

        fclose(fstab);
    }

    if (!fsType) {
        printf("mount: filesystem type expected\n");
        return 1;
    }

    if (cmd && cmd < end) {
        printf("mount: unexpected arguments\n");
        return 1;
    }

    /* need to deal with options */
    if (opts) {
        char * end;
        char * start = opts;

        newOpts = alloca(strlen(opts) + 1);
        *newOpts = '\0';

        while (*start) {
            end = strchr(start, ',');
            if (!end) {
                end = start + strlen(start);
            } else {
                *end = '\0';
                end++;
            }

            if (!strcmp(start, "ro"))
                flags |= MS_RDONLY;
            else if (!strcmp(start, "rw"))
                flags &= ~MS_RDONLY;
            else if (!strcmp(start, "nosuid"))
                flags |= MS_NOSUID;
            else if (!strcmp(start, "suid"))
                flags &= ~MS_NOSUID;
            else if (!strcmp(start, "nodev"))
                flags |= MS_NODEV;
            else if (!strcmp(start, "dev"))
                flags &= ~MS_NODEV;
            else if (!strcmp(start, "noexec"))
                flags |= MS_NOEXEC;
            else if (!strcmp(start, "exec"))
                flags &= ~MS_NOEXEC;
            else if (!strcmp(start, "sync"))
                flags |= MS_SYNCHRONOUS;
            else if (!strcmp(start, "async"))
                flags &= ~MS_SYNCHRONOUS;
            else if (!strcmp(start, "nodiratime"))
                flags |= MS_NODIRATIME;
            else if (!strcmp(start, "diratime"))
                flags &= ~MS_NODIRATIME;
            else if (!strcmp(start, "noatime"))
                flags |= MS_NOATIME;
            else if (!strcmp(start, "atime"))
                flags &= ~MS_NOATIME;
            else if (!strcmp(start, "relatime"))
                flags |= MS_RELATIME;
            else if (!strcmp(start, "norelatime"))
                flags &= ~MS_RELATIME;
            else if (!strcmp(start, "remount"))
                flags |= MS_REMOUNT;
            else if (!strcmp(start, "bind"))
                flags |= MS_BIND;
            else if (!strcmp(start, "defaults"))
                ;
            else {
                if (*newOpts)
                    strcat(newOpts, ",");
                strcat(newOpts, start);
            }

            start = end;
        }

        opts = newOpts;
    }

    device = strdupa(spec);

    if (!device) {
        printf("mount: could not find filesystem '%s'\n", spec);
        return 1;
    }

    {
        char *mount_opts = NULL;
	mount_opts = opts;
        if (mount(device, mntPoint, fsType, flags, mount_opts) < 0) {
            printf("mount: error mounting %s on %s as %s: %m\n",
                    device, mntPoint, fsType);
            rc = 1;
        }
    }

    return rc;
}

/* remove all files/directories below dirName -- don't cross mountpoints */
static int
recursiveRemove(char * dirName)
{
    struct stat sb,rb;
    DIR * dir;
    struct dirent * d;
    char * strBuf = alloca(strlen(dirName) + 1024);

    if (!(dir = opendir(dirName))) {
        printf("error opening %s: %m\n", dirName);
        return 0;
    }

    if (fstat(dirfd(dir),&rb)) {
        printf("unable to stat %s: %m\n", dirName);
        closedir(dir);
        return 0;
    }

    errno = 0;
    while ((d = readdir(dir))) {
        errno = 0;

        if (!strcmp(d->d_name, ".") || !strcmp(d->d_name, "..")) {
            errno = 0;
            continue;
        }

        strcpy(strBuf, dirName);
        strcat(strBuf, "/");
        strcat(strBuf, d->d_name);

        if (lstat(strBuf, &sb)) {
            printf("failed to stat %s: %m\n", strBuf);
            errno = 0;
            continue;
        }

        /* only descend into subdirectories if device is same as dir */
        if (S_ISDIR(sb.st_mode)) {
            if (sb.st_dev == rb.st_dev) {
	        recursiveRemove(strBuf);
                if (rmdir(strBuf))
                    printf("failed to rmdir %s: %m\n", strBuf);
            }
            errno = 0;
            continue;
        }

        if (unlink(strBuf)) {
            printf("failed to remove %s: %m\n", strBuf);
            errno = 0;
            continue;
        }
    }

    if (errno) {
        closedir(dir);
        printf("error reading from %s: %m\n", dirName);
        return 1;
    }

    closedir(dir);

    return 0;
}

static void
mountMntEnt(const struct mntent *mnt)
{
    char *start = NULL, *end;
    char *target = NULL;
    struct stat sb;
    
    printf("mounting %s\n", mnt->mnt_dir);
    if (asprintfa(&target, ".%s", mnt->mnt_dir) < 0) {
        printf("setuproot: out of memory while mounting %s\n",
                mnt->mnt_dir);
        return;
    }
    
    if (stat(target, &sb) < 0)
        return;
    
    if (asprintf(&start, "-o %s -t %s %s .%s\n",
            mnt->mnt_opts, mnt->mnt_type, mnt->mnt_fsname,
            mnt->mnt_dir) < 0) {
        printf("setuproot: out of memory while mounting %s\n",
                mnt->mnt_dir);
        return;
    }
    
    end = start + 1;
    while (*end && (*end != '\n'))
        end++;
    /* end points to the \n at the end of the command */
    
    if (mountCommand(start, end) != 0)
        printf("setuproot: mount returned error\n");
}

static int
setuprootCommand(char *new)
{
    FILE *fp;

    printf("Setting up new root fs\n");

    if (chdir(new)) {
        printf("setuproot: chdir(%s) failed: %m\n", new);
        return 1;
    }

    if (mount("/dev", "./dev", NULL, MS_BIND, NULL) < 0)
        printf("setuproot: moving /dev failed: %m\n");

        fp = setmntent("./etc/fstab.sys", "r");
        if (fp)
            printf("using fstab.sys from mounted FS\n");
        else {
            fp = setmntent("/etc/fstab.sys", "r");
            if (fp)
                printf("using fstab.sys from initrd\n");
        }
        if (fp) {
            struct mntent *mnt;

            while((mnt = getmntent(fp)))
                mountMntEnt(mnt);
            endmntent(fp);
        } else {
            struct {
                char *source;
                char *target;
                char *type;
                int flags;
                void *data;
                int raise;
            } fstab[] = {
                { "/proc", "./proc", "proc", 0, NULL },
                { "/sys", "./sys", "sysfs", 0, NULL },
#if 0
                { "/dev/pts", "./dev/pts", "devpts", 0, "gid=5,mode=620" },
                { "/dev/shm", "./dev/shm", "tmpfs", 0, NULL },
                { "/selinux", "/selinux", "selinuxfs", 0, NULL },
#endif
                { NULL, }
            };
            int i = 0;

            printf("no fstab.sys, mounting internal defaults\n");
            for (; fstab[i].source != NULL; i++) {
                if (mount(fstab[i].source, fstab[i].target, fstab[i].type,
                            fstab[i].flags, fstab[i].data) < 0)
                    printf("setuproot: error mounting %s: %m\n",
                            fstab[i].source);
            }
        }

    chdir("/");
    return 0;
}

int main(int argc, char **argv) 
{
    /*  Don't try to unmount the old "/", there's no way to do it. */
    const char *umounts[] = { "/dev", "/proc", "/sys", NULL };
    char *new = NULL;
    int fd, i = 0;

    argv++;
    new = argv[0];
    argv++;
    printf("Switching to root: %s", new);

    setuprootCommand(new);

    fd = open("/", O_RDONLY);
    for (; umounts[i] != NULL; i++) {
        printf("unmounting old %s\n", umounts[i]);
        if (umount2(umounts[i], MNT_DETACH) < 0) {
            printf("ERROR unmounting old %s: %m\n",umounts[i]);
            printf("forcing unmount of %s\n", umounts[i]);
            umount2(umounts[i], MNT_FORCE);
        }
    }
    i=0;

    chdir(new);

    recursiveRemove("/");

    if (mount(new, "/", NULL, MS_MOVE, NULL) < 0) {
        printf("switchroot: mount failed: %m\n");
        close(fd);
        return 1;
    }

    if (chroot(".")) {
        printf("switchroot: chroot() failed: %m\n");
        close(fd);
        return 1;
    }

    /* release the old "/" */
    close(fd);

    close(3);
    if ((fd = open("/dev/console", O_RDWR)) < 0) {
        printf("ERROR opening /dev/console: %m\n");
        printf("Trying to use fd 0 instead.\n");
        fd = dup2(0, 3);
    } else {
        setFdCoe(fd, 0);
        if (fd != 3) {
            dup2(fd, 3);
            close(fd);
            fd = 3;
        }
    }
    close(0);
    dup2(fd, 0);
    close(1);
    dup2(fd, 1);
    close(2);
    dup2(fd, 2);
    close(fd);

    if (access(argv[0], X_OK)) {
        printf("WARNING: can't access %s\n", argv[0]);
    }

    execv(argv[0], argv);

    printf("exec of init (%s) failed!!!: %m\n", argv[0]);
    return 1;
}
