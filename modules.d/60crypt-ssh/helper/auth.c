#include <sys/ioctl.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <fcntl.h>
#include <termios.h>
#include <unistd.h>
#include <string.h>

// Based on:
//  https://bugzilla.redhat.com/show_bug.cgi?id=524727
//  http://roosbertl.blogspot.de/2012/12/centos6-disk-encryption-with-remote.html

const char *prompt="Passphrase: ";

int main (int argc, const char * argv[]) {
	char *passphrase;
	int i;

	int fd = open("/dev/console", O_RDONLY);
	if (fd < 0) return 2;

	passphrase = getpass(prompt);

	for (const char * str = passphrase; *str; ++str) ioctl(fd, TIOCSTI, str);
	ioctl(fd, TIOCSTI, "\r");

	// clear string immediately
	int len = strlen(passphrase);
	for (i=0;i<len;i++) passphrase[i] = 0;
	return 0;
}
