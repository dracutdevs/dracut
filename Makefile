VERSION=0.5
GITVERSION=$(shell [ -d .git ] && git rev-list  --abbrev-commit  -n 1 HEAD  |cut -b 1-8)

prefix = /usr
datadir = ${prefix}/share
pkglibdir = ${datadir}/dracut
sysconfdir = ${prefix}/etc
sbindir = ${prefix}/sbin
mandir = ${prefix}/share/man

modules.d/99base/switch_root: switch_root.c
	gcc -D _GNU_SOURCE -D 'PACKAGE_STRING="dracut"' -std=gnu99 -fsigned-char -g -O2 -o modules.d/99base/switch_root switch_root.c	

all: modules.d/99base/switch_root

.PHONY: install clean archive rpm testimage test all check

install:
	mkdir -p $(DESTDIR)$(pkglibdir)
	mkdir -p $(DESTDIR)$(sbindir)
	mkdir -p $(DESTDIR)$(sysconfdir)
	mkdir -p $(DESTDIR)$(pkglibdir)/modules.d
	mkdir -p $(DESTDIR)$(mandir)/man8
	install -m 0755 dracut $(DESTDIR)$(sbindir)/dracut
	install -m 0755 dracut-gencmdline $(DESTDIR)$(sbindir)/dracut-gencmdline
	install -m 0755 modules.d/99base/switch_root $(DESTDIR)$(sbindir)/switch_root
	install -m 0644 dracut.conf $(DESTDIR)$(sysconfdir)/dracut.conf
	install -m 0755 dracut-functions $(DESTDIR)$(pkglibdir)/dracut-functions
	cp -arx modules.d $(DESTDIR)$(pkglibdir)
	install -m 0644 dracut.8 $(DESTDIR)$(mandir)/man8
	rm $(DESTDIR)$(pkglibdir)/modules.d/99base/switch_root

clean:
	rm -f *~
	rm -f modules.d/99base/switch_root
	rm -f test-*.img
	make -C test clean

archive: dracut-$(VERSION)-$(GITVERSION).tar.bz2

dist: dracut-$(VERSION).tar.bz2

dracut-$(VERSION).tar.bz2:
	git archive --format=tar $(VERSION) --prefix=dracut-$(VERSION)/ |bzip2 > dracut-$(VERSION).tar.bz2

dracut-$(VERSION)-$(GITVERSION).tar.bz2:
	git archive --format=tar HEAD --prefix=dracut-$(VERSION)-$(GITVERSION)/ |bzip2 > dracut-$(VERSION)-$(GITVERSION).tar.bz2


rpm: dracut-$(VERSION).tar.bz2
	rpmbuild --define "_topdir $$PWD" --define "_sourcedir $$PWD" --define "_specdir $$PWD" --define "_srcrpmdir $$PWD" --define "_rpmdir $$PWD" -ba dracut.spec 
	rm -fr BUILD BUILDROOT

gitrpm: dracut-$(VERSION)-$(GITVERSION).tar.bz2
	rpmbuild --define "_topdir $$PWD" --define "_sourcedir $$PWD" --define "_specdir $$PWD" --define "_srcrpmdir $$PWD" --define "_rpmdir $$PWD" --define "gittag $(GITVERSION)" -ba dracut.spec 
	rm -fr BUILD BUILDROOT

check: all
	@ret=0;for i in modules.d/99base/init modules.d/*/*.sh; do \
		dash -n "$$i" ; ret=$$(($$ret+$$?)); \
	done;exit $$ret
	make -C test check

testimage: all
	./dracut -l -a debug -f test-$(shell uname -r).img $(shell uname -r)
	@echo wrote  test-$(shell uname -r).img 
