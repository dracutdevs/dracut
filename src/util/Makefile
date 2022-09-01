CC ?= cc
CFLAGS ?= -O2 -g -Wall -std=gnu99 -D_FILE_OFFSET_BITS=64 -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2
LDFLAGS ?= 

UTIL_OBJECTS = util.o
UTIL_SOURCES = util.c

%.o : %.c
	$(CC) -c $(CFLAGS) $< -o $@

all: util

util: $(UTIL_OBJECTS)
	$(CC) $(LDFLAGS) $< -o $@

clean:
	$(RM) util $(UTIL_OBJECTS)

.PHONY: all clean

util.o: util.c