VERSION=0.1
GITVERSION=$(shell [ -d .git ] && git rev-list  --abbrev-commit  -n 1 HEAD  |cut -b 1-8)

modules.d/99base/switch_root: switch_root.c
	gcc -o modules.d/99base/switch_root switch_root.c	

all: modules.d/99base/switch_root

.PHONY: install clean archive rpm testimage test all check

install:
	mkdir -p $(DESTDIR)/usr/lib/dracut
	mkdir -p $(DESTDIR)/sbin
	mkdir -p $(DESTDIR)/etc
	mkdir -p $(DESTDIR)/usr/lib/dracut/modules.d
	install -m 0755 dracut $(DESTDIR)/sbin/dracut
	install -m 0644 dracut.conf $(DESTDIR)/etc/dracut.conf
	install -m 0755 dracut-functions $(DESTDIR)/usr/lib/dracut/dracut-functions
	cp -arx modules.d $(DESTDIR)/usr/lib/dracut/

clean:
	rm -f *~
	rm -f modules.d/99base/switch_root
	rm -f test-*.img
	make -C test clean

archive: dracut-$(VERSION)-$(GITVERSION).tar.bz2

dracut-$(VERSION)-$(GITVERSION).tar.bz2:
	git archive --format=tar HEAD --prefix=dracut-$(VERSION)-$(GITVERSION)/ |bzip2 > dracut-$(VERSION)-$(GITVERSION).tar.bz2

rpm: dracut-$(VERSION)-$(GITVERSION).tar.bz2
	rpmbuild --define "_topdir $$PWD" --define "_sourcedir $$PWD" --define "_specdir $$PWD" --define "_srcrpmdir $$PWD" --define "_rpmdir $$PWD" --define "gittag $(GITVERSION)" -ba dracut.spec 
	rm -fr BUILD BUILDROOT

check: all
	@ret=0;for i in modules.d/99base/init modules.d/*/*.sh; do \
		dash -n "$$i" ; ret=$$(($$ret+$$?)); \
	done;exit $$ret
	make -C test check

testimage: all
	./dracut -l -f test-$(shell uname -r).img $(shell uname -r)
	@echo wrote  test-$(shell uname -r).img 
