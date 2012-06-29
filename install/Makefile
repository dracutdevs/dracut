prefix ?= /usr
bindir ?= ${prefix}/bin
strip  ?= -s

all: dracut-install

dracut-install: dracut-install.c hashmap.c log.c util.c
	gcc -std=gnu99 -O2 -g -Wall -o dracut-install dracut-install.c hashmap.c log.c util.c

install: dracut-install
	install $(strip) -m 0755 dracut-install $(DESTDIR)$(bindir)/dracut-install

clean:
	rm -f dracut-install *~

indent:
	indent -i8 -nut -br -linux -l120 dracut-install.c
