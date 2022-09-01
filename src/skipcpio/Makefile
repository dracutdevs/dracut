CC ?= cc
CFLAGS ?= -O2 -g -Wall -std=gnu99 -D_FILE_OFFSET_BITS=64 -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2
LDFLAGS ?= 

SKIPCPIO_OBJECTS = skipcpio.o
SKIPCPIO_SOURCES = skipcpio.c

%.o : %.c
	$(CC) -c $(CFLAGS) $< -o $@

all: skipcpio

skipcpio: $(SKIPCPIO_OBJECTS)
	$(CC) $(LDFLAGS) $< -o $@

clean:
	$(RM) skipcpio $(SKIPCPIO_OBJECTS)

.PHONY: all clean

skipcpio.o: skipcpio.c
