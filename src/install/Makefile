CC ?= cc
CFLAGS ?= -O2 -g -Wall -std=gnu99 -D_FILE_OFFSET_BITS=64 -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2
LDFLAGS ?=
LDLIBS ?=

-include ../../Makefile.inc

DRACUT_INSTALL_OBJECTS = dracut-install.o hashmap.o log.o strv.o util.o
DRACUT_INSTALL_SOURCES = dracut-install.c hashmap.c log.c strv.c util.c
DRACUT_INSTALL_HEADERS = hashmap.h log.h strv.h util.h macro.h

%.o : %.c
	$(CC) -c $(CFLAGS) $(KMOD_CFLAGS) $< -o $@

all: dracut-install

dracut-install: $(DRACUT_INSTALL_OBJECTS)
	$(CC) $(LDFLAGS) -o $@ $(DRACUT_INSTALL_OBJECTS) $(LDLIBS) $(FTS_LIBS) $(KMOD_LIBS)

clean:
	$(RM) dracut-install $(DRACUT_INSTALL_OBJECTS)

.PHONY: all clean

dracut-install.o: dracut-install.c log.h macro.h hashmap.h util.h
hashmap.o: hashmap.c util.h macro.h log.h hashmap.h
log.o: log.c log.h macro.h util.h
util.o: util.c util.h macro.h log.h
strv.o: strv.c strv.h util.h macro.h log.h