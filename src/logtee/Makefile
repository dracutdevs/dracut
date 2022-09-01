CC ?= cc
CFLAGS ?= -O2 -g -Wall -std=gnu99 -D_FILE_OFFSET_BITS=64 -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2
LDFLAGS ?= 

LOGTEE_OBJECTS = logtee.o
LOGTEE_SOURCES = logtee.c

%.o : %.c
	$(CC) -c $(CFLAGS) $< -o $@

all: logtee

logtee: $(LOGTEE_OBJECTS)
	$(CC) $(LDFLAGS) $< -o $@

clean:
	$(RM) logtee $(LOGTEE_OBJECTS)

.PHONY: all clean

logtee.o: logtee.c