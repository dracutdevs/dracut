#define _GNU_SOURCE
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <limits.h>

#define BUFLEN 4096

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

	slen = 0;

	do {
		len = splice(STDIN_FILENO, NULL, fd, NULL,
			     BUFLEN, SPLICE_F_MOVE);

		if (len < 0) {
			if (errno == EAGAIN)
				continue;
			perror("tee");
			exit(EXIT_FAILURE);
		} else
			if (len == 0)
				break;
		slen += len;
		if ((slen/BUFLEN) > 0) {
			fprintf(stderr, ".");
		}
		slen = slen % BUFLEN;

	} while (1);
	close(fd);
	fprintf(stderr, "\n");
	exit(EXIT_SUCCESS);
}