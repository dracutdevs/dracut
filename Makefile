VERSION=010
GITVERSION=$(shell [ -d .git ] && git rev-list  --abbrev-commit  -n 1 HEAD  |cut -b 1-8)

prefix ?= /usr
datadir ?= ${prefix}/share
pkglibdir ?= ${datadir}/dracut
sysconfdir ?= ${prefix}/etc
sbindir ?= ${prefix}/sbin
mandir ?= ${prefix}/share/man

manpages = dracut.8 dracut.kernel.7 dracut.conf.5 dracut-catimages.8  dracut-gencmdline.8

.PHONY: install clean archive rpm testimage test all check AUTHORS doc

doc: $(manpages) dracut.html
all: syncheck

%: %.xml
	xsltproc -o $@ -nonet http://docbook.sourceforge.net/release/xsl/current/manpages/docbook.xsl $<

dracut.html: dracut.xml $(manpages)
	xsltproc -o dracut.html --xinclude -nonet \
		--stringparam draft.mode yes \
		--stringparam html.stylesheet http://docs.redhat.com/docs/en-US/Common_Content/css/default.css \
		http://docbook.sourceforge.net/release/xsl/current/xhtml/docbook.xsl dracut.xml

install: doc
	mkdir -p $(DESTDIR)$(pkglibdir)
	mkdir -p $(DESTDIR)$(sbindir)
	mkdir -p $(DESTDIR)$(sysconfdir)
	mkdir -p $(DESTDIR)$(pkglibdir)/modules.d
	mkdir -p $(DESTDIR)$(mandir)/man{5,7,8}
	install -m 0755 dracut $(DESTDIR)$(sbindir)/dracut
	install -m 0755 dracut-gencmdline $(DESTDIR)$(sbindir)/dracut-gencmdline
	install -m 0755 dracut-catimages $(DESTDIR)$(sbindir)/dracut-catimages
	install -m 0755 mkinitrd-dracut.sh $(DESTDIR)$(sbindir)/mkinitrd
	install -m 0755 lsinitrd $(DESTDIR)$(sbindir)/lsinitrd
	install -m 0644 dracut.conf $(DESTDIR)$(sysconfdir)/dracut.conf
	mkdir -p $(DESTDIR)$(sysconfdir)/dracut.conf.d
	install -m 0755 dracut-functions $(DESTDIR)$(pkglibdir)/dracut-functions
	install -m 0755 dracut-logger $(DESTDIR)$(pkglibdir)/dracut-logger
	cp -arx modules.d $(DESTDIR)$(pkglibdir)
	install -m 0644 dracut.8 $(DESTDIR)$(mandir)/man8
	install -m 0644 dracut-catimages.8 $(DESTDIR)$(mandir)/man8
	install -m 0644 dracut-gencmdline.8 $(DESTDIR)$(mandir)/man8
	install -m 0644 dracut.conf.5 $(DESTDIR)$(mandir)/man5
	install -m 0644 dracut.kernel.7 $(DESTDIR)$(mandir)/man7

clean:
	$(RM) *~
	$(RM) */*~
	$(RM) */*/*~
	$(RM) test-*.img
	$(RM) dracut-*.rpm dracut-*.tar.bz2
	$(RM) $(manpages) dracut.html
	$(MAKE) -C test clean

archive: dracut-$(VERSION)-$(GITVERSION).tar.bz2

dist: dracut-$(VERSION).tar.gz

dracut-$(VERSION).tar.bz2:
	git archive --format=tar $(VERSION) --prefix=dracut-$(VERSION)/ |bzip2 > dracut-$(VERSION).tar.bz2

dracut-$(VERSION).tar.gz:
	git archive --format=tar $(VERSION) --prefix=dracut-$(VERSION)/ |gzip > dracut-$(VERSION).tar.gz

rpm: dracut-$(VERSION).tar.bz2
	mkdir -p rpmbuild
	cp dracut-$(VERSION).tar.bz2 rpmbuild
	cd rpmbuild; ../git2spec.pl $(VERSION) < ../dracut.spec > dracut.spec; \
	rpmbuild --define "_topdir $$PWD" --define "_sourcedir $$PWD" \
	        --define "_specdir $$PWD" --define "_srcrpmdir $$PWD" \
		--define "_rpmdir $$PWD" -ba dracut.spec || :; \
	cd ..;
	rm -fr rpmbuild

syncheck:
	@ret=0;for i in dracut-logger modules.d/99base/init modules.d/*/*.sh; do \
                [ "$${i##*/}" = "module-setup.sh" ] && continue; \
                [ "$${i##*/}" = "caps.sh" ] && continue; \
		dash -n "$$i" ; ret=$$(($$ret+$$?)); \
	done;exit $$ret
	@ret=0;for i in dracut modules.d/02caps/caps.sh modules.d/*/module-setup.sh; do \
		bash -n "$$i" ; ret=$$(($$ret+$$?)); \
	done;exit $$ret

check: all syncheck
	$(MAKE) -C test check

testimage: all
	./dracut -l -a debug -f test-$(shell uname -r).img $(shell uname -r)
	@echo wrote  test-$(shell uname -r).img 

testimages: all
	./dracut -l -a debug --kernel-only -f test-kernel-$(shell uname -r).img $(shell uname -r)
	@echo wrote  test-$(shell uname -r).img 
	./dracut -l -a debug --no-kernel -f test-dracut.img $(shell uname -r)
	@echo wrote  test-dracut.img 

hostimage: all
	./dracut -H -l -a debug -f test-$(shell uname -r).img $(shell uname -r)
	@echo wrote  test-$(shell uname -r).img 

AUTHORS:
	git shortlog  --numbered --summary -e |while read a rest; do echo $$rest;done > AUTHORS
