/*
 * switchroot.c - switch to new root directory and start init.
 *
 * Copyright 2002-2008 Red Hat, Inc.  All rights reserved.
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
 * Authors:
 * 	Peter Jones <pjones@redhat.com>
 *	Jeremy Katz <katzj@redhat.com>
 */

#define _GNU_SOURCE 1

#include <sys/mount.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/param.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <ctype.h>

#ifndef MS_MOVE
#define MS_MOVE 8192
#endif

#ifndef MNT_DETACH
#define MNT_DETACH 0x2
#endif

enum {
	ok,
	err_no_directory,
	err_usage,
};

static int readFD(int fd, char **buf)
{
	char *p;
	size_t size = 16384;
	int s = 0, filesize = 0;

	if (!(*buf = calloc (16384, sizeof (char))))
		return -1;

	do {
		p = *buf + filesize;
		s = read(fd, p, 16384 - s);
		if (s < 0)
			break;
		filesize += s;
		/* only exit for empty reads */
		if (s == 0)
			break;
		else if (s == 16384) {
			*buf = realloc(*buf, size + 16384);
			memset(*buf + size, '\0', 16384);
			size += s;
			s = 0;
		} else {
			size += s;
		}
	} while (1);

	*buf = realloc(*buf, filesize+1);
	(*buf)[filesize] = '\0';

	return *buf ? filesize : -1;
}

static char *getKernelCmdLine(void)
{
	static char *cmdline = NULL;
	int fd = -1;
	int errnum;

	fd = open("./proc/cmdline", O_RDONLY);
	if (fd < 0) {
		errnum = errno;
		fprintf(stderr, "Error: Could not open ./proc/cmdline: %m\n");
		errno = errnum;
		return NULL;
	}
	
	if (readFD(fd, &cmdline) < 0) {
		errnum = errno;
		fprintf(stderr, "Error: could not read ./proc/cmdline: %m\n");
		close(fd);
		errno = errnum;
		return NULL;
	}
	close(fd);

	return cmdline;
}

/* get the start of a kernel arg "arg".  returns everything after it
 * (useful for things like getting the args to init=).  so if you only
 * want one arg, you need to terminate it at the n */
static char *getKernelArg(char *arg)
{
	char *start;
	char *cmdline;
	int len;

	cmdline = start = getKernelCmdLine();
	if (start == NULL)
		return NULL;

	while (*start) {
		if (isspace(*start)) {
			start++;
			continue;
		}

		len = strlen(arg);
		/* don't return if it's a different argument that merely starts
		 * like this one. */
		if (strncmp(start, arg, len) == 0) {
			if (start[len] == '=')
				return start + len + 1;
			if (!start[len] || isspace(start[len]))
				return start + len;
		}
		while (*++start && !isspace(*start))
			;
	}

	return NULL;
}

#define MAX_INIT_ARGS 32
static int build_init_args(char **init, char ***initargs_out)
{
	const char *initprogs[] = { "./sbin/init", "./etc/init",
				    "./bin/init", "./bin/sh", NULL };
	const char *ignoreargs[] = { "console=", "BOOT_IMAGE=", NULL };
	char *cmdline = NULL;
	char **initargs;

	int i = 0;

	*init = getKernelArg("init");

	if (*init == NULL) {
		int j;
		cmdline = getKernelCmdLine();
		if (cmdline == NULL)
			return -1;

		for (j = 0; initprogs[j] != NULL; j++) {
			if (!access(initprogs[j], X_OK)) {
				*init = strdup(initprogs[j]);
				break;
			}
		}
	}

	initargs = (char **)calloc(MAX_INIT_ARGS+1, sizeof (char *));
	if (initargs == NULL)
		return -1;

	if (cmdline && *init) {
		initargs[i++] = *init;
	} else {
		cmdline = *init;
		initargs[0] = NULL;
	}

	if (cmdline) {
		char quote = '\0';
		char *chptr;
		char *start;

		start = chptr = cmdline;
		for (; (i < MAX_INIT_ARGS) && (*start != '\0'); i++) {
			while (*chptr && (*chptr != quote)) {
				if (isspace(*chptr) && quote == '\0')
					break;
				if (*chptr == '"' || *chptr == '\'')
					quote = *chptr;
				chptr++;
			}

			if (quote == '"' || quote == '\'')
				chptr++;
			if (*chptr != '\0')
				*(chptr++) = '\0';

			/* There are some magic parameters added *after*
			 * everything you pass, including a console= from the 
			 * x86_64 kernel and BOOT_IMAGE= by syslinux.  Bash
			 * doesn't know what they mean, so it then exits, init 
			 * gets killed, desaster ensues.  *sigh*.
			 */
			int j;
			for (j = 0; ignoreargs[j] != NULL; j++) {
				if (cmdline == *init && !strncmp(start, ignoreargs[j], strlen(ignoreargs[j]))) {
					if (!*chptr)
						initargs[i] = NULL;
					else
						i--;
					start = chptr;
					break;
				}
			}
			if (start == chptr)
				continue;

			if (start[0] == '\0')
				i--;
			else
				initargs[i] = strdup(start);
			start = chptr;
		}
	}

	if (initargs[i-1] != NULL)
		initargs[i] = NULL;

	*initargs_out = initargs;
	

	return 0;
}

static void switchroot(const char *newroot)
{
	/*  Don't try to unmount the old "/", there's no way to do it. */
	const char *umounts[] = { "/dev", "/proc", "/sys", NULL };
	char *init, **initargs;
	int errnum;
	int rc;
	int i;

	for (i = 0; umounts[i] != NULL; i++) {
		char newmount[PATH_MAX];
		strcpy(newmount, newroot);
		strcat(newmount, umounts[i]);
		if (mount(umounts[i], newmount, NULL, MS_MOVE, NULL) < 0) {
			fprintf(stderr, "Error mount moving old %s %s %m\n",
				umounts[i], newmount);
			fprintf(stderr, "Forcing unmount of %s\n", umounts[i]);
			umount2(umounts[i], MNT_FORCE);
		}
	}

	chdir(newroot);

	rc = build_init_args(&init, &initargs);
	if (rc < 0)
		return;

	if (mount(newroot, "/", NULL, MS_MOVE, NULL) < 0) {
		errnum = errno;
		fprintf(stderr, "switchroot: mount failed: %m\n");
		errno = errnum;
		return;
	}

	if (chroot(".")) {
		errnum = errno;
		fprintf(stderr, "switchroot: chroot failed: %m\n");
		errno = errnum;
		return;
	}

	if (access(initargs[0], X_OK))
		fprintf(stderr, "WARNING: can't access %s\n", initargs[0]);

	execv(initargs[0], initargs);
	return;
}

static void usage(FILE *output)
{
	fprintf(output, "usage: switchroot {-n|--newroot} <newrootdir>\n");
	if (output == stderr)
		exit(err_usage);
	exit(ok);
}

int main(int argc, char *argv[])
{
	int i;
	char *newroot = NULL;

	for (i = 1; i < argc; i++) {
		if (!strcmp(argv[i], "--help")
				|| !strcmp(argv[i], "-h")
				|| !strcmp(argv[i], "--usage")) {
			usage(stdout);
		} else if (!strcmp(argv[i], "-n")
				|| !strcmp(argv[i], "--newroot")) {
			newroot = argv[++i];
		} else if (!strncmp(argv[i], "--newroot=", 10)) {
			newroot = argv[i] + 10;
		} else {
			usage(stderr);
		}
	}

	if (newroot == NULL || newroot[0] == '\0') {
		usage(stderr);
	}

	switchroot(newroot);

	fprintf(stderr, "switchroot has failed.  Sorry.\n");
	return 1;
}

/*
 * vim:noet:ts=8:sw=8:sts=8
 */
