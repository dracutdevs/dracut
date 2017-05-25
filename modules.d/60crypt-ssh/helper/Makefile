CFLAGS=-std=gnu99 -O2 -Wall

.PHONY: all

all: console_auth unlock

test:	crypttab-test
	

clean:
	rm -f *.o console_auth unlock crypttab-test

console_auth:	auth.c
	gcc $(CFLAGS) $^ -o $@

unlock:	crypttab.o unlock.o
	gcc -lblkid $^ -o $@

crypttab-test: crypttab-test.c crypttab.o crypttab-test-data
	gcc crypttab-test.c $(CFLAGS) crypttab.o -lblkid -o crypttab-test
	./crypttab-test
