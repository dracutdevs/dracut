#define _GNU_SOURCE
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <limits.h>

int
main(int argc, char *argv[])
{
	int fd;
	int len, slen;

	if (argc != 2) {
		fprintf(stderr, "Usage: %s <file>\n", argv[0]);
		exit(EXIT_FAILURE);
	}

	fd = open(argv[1], O_WRONLY | O_CREAT | O_TRUNC, 0644);
	if (fd == -1) {
		perror("open");
		exit(EXIT_FAILURE);
	}

	fprintf(stderr, "Logging to %s: ", argv[1]);

	do {
		len = splice(STDIN_FILENO, NULL, fd, NULL,
			     65536, SPLICE_F_MOVE);

		if (len < 0) {
			if (errno == EAGAIN)
				continue;
			perror("tee");
			exit(EXIT_FAILURE);
		} else
			if (len == 0)
				break;
		fprintf(stderr, ".", len);
	} while (1);
	close(fd);
	fprintf(stderr, "\n");
	exit(EXIT_SUCCESS);
}

