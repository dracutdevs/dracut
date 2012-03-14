VERSION=017
GITVERSION=$(shell [ -d .git ] && git rev-list  --abbrev-commit  -n 1 HEAD  |cut -b 1-8)

prefix ?= /usr
libdir ?= ${prefix}/lib
datadir ?= ${prefix}/share
pkglibdir ?= ${libdir}/dracut
sysconfdir ?= ${prefix}/etc
bindir ?= ${prefix}/bin
mandir ?= ${prefix}/share/man

manpages = dracut.8 dracut.cmdline.7 dracut.conf.5 dracut-catimages.8

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
	mkdir -p $(DESTDIR)$(bindir)
	mkdir -p $(DESTDIR)$(sysconfdir)
	mkdir -p $(DESTDIR)$(pkglibdir)/modules.d
	mkdir -p $(DESTDIR)$(mandir)/man5 $(DESTDIR)$(mandir)/man7 $(DESTDIR)$(mandir)/man8
	install -m 0755 dracut.sh $(DESTDIR)$(bindir)/dracut
	install -m 0755 dracut-catimages.sh $(DESTDIR)$(bindir)/dracut-catimages
	install -m 0755 mkinitrd-dracut.sh $(DESTDIR)$(bindir)/mkinitrd
	install -m 0755 lsinitrd.sh $(DESTDIR)$(bindir)/lsinitrd
	install -m 0644 dracut.conf $(DESTDIR)$(sysconfdir)/dracut.conf
	mkdir -p $(DESTDIR)$(sysconfdir)/dracut.conf.d
	install -m 0755 dracut-functions.sh $(DESTDIR)$(pkglibdir)/dracut-functions.sh
	ln -s dracut-functions.sh $(DESTDIR)$(pkglibdir)/dracut-functions
	install -m 0755 dracut-logger.sh $(DESTDIR)$(pkglibdir)/dracut-logger.sh
	install -m 0755 dracut-initramfs-restore.sh $(DESTDIR)$(pkglibdir)/dracut-initramfs-restore
	cp -arx modules.d $(DESTDIR)$(pkglibdir)
	install -m 0644 dracut.8 $(DESTDIR)$(mandir)/man8/dracut.8
	install -m 0644 dracut-catimages.8 $(DESTDIR)$(mandir)/man8/dracut-catimages.8
	install -m 0644 dracut.conf.5 $(DESTDIR)$(mandir)/man5/dracut.conf.5
	install -m 0644 dracut.cmdline.7 $(DESTDIR)$(mandir)/man7/dracut.cmdline.7
	ln -s dracut.cmdline.7 $(DESTDIR)$(mandir)/man7/dracut.kernel.7
	if [ -n "$(systemdsystemunitdir)" ]; then \
		mkdir -p $(DESTDIR)$(systemdsystemunitdir); \
		install -m 0644 dracut-shutdown.service $(DESTDIR)$(systemdsystemunitdir); \
		mkdir -p $(DESTDIR)$(systemdsystemunitdir)/reboot.target.wants; \
		mkdir -p $(DESTDIR)$(systemdsystemunitdir)/shutdown.target.wants; \
		ln -s ../dracut-shutdown.service $(DESTDIR)$(systemdsystemunitdir)/reboot.target.wants/dracut-shutdown.service; \
		ln -s ../dracut-shutdown.service $(DESTDIR)$(systemdsystemunitdir)/shutdown.target.wants/dracut-shutdown.service; \
	fi

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
	rpmbuild=$$(mktemp -d -t rpmbuild-dracut.XXXXXX); src=$$(pwd); \
	cp dracut-$(VERSION).tar.bz2 "$$rpmbuild"; \
	$$src/git2spec.pl $(VERSION) "$$rpmbuild" < dracut.spec > $$rpmbuild/dracut.spec; \
	(cd "$$rpmbuild"; rpmbuild --define "_topdir $$PWD" --define "_sourcedir $$PWD" \
	        --define "_specdir $$PWD" --define "_srcrpmdir $$PWD" \
		--define "_rpmdir $$PWD" -ba dracut.spec; ) && \
	( mv "$$rpmbuild"/noarch/*.rpm .; mv "$$rpmbuild"/*.src.rpm .;rm -fr "$$rpmbuild"; ls *.rpm )

syncheck:
	@ret=0;for i in dracut-initramfs-restore.sh dracut-logger.sh \
                        modules.d/99base/init.sh modules.d/*/*.sh; do \
                [ "$${i##*/}" = "module-setup.sh" ] && continue; \
                [ "$${i##*/}" = "caps.sh" ] && continue; \
		dash -n "$$i" ; ret=$$(($$ret+$$?)); \
	done;exit $$ret
	@ret=0;for i in *.sh mkinitrd-dracut.sh modules.d/02caps/caps.sh \
	                modules.d/*/module-setup.sh; do \
		bash -n "$$i" ; ret=$$(($$ret+$$?)); \
	done;exit $$ret

check: all syncheck
	$(MAKE) -C test check

testimage: all
	./dracut.sh -l -a debug -f test-$(shell uname -r).img $(shell uname -r)
	@echo wrote  test-$(shell uname -r).img 

testimages: all
	./dracut.sh -l -a debug --kernel-only -f test-kernel-$(shell uname -r).img $(shell uname -r)
	@echo wrote  test-$(shell uname -r).img 
	./dracut.sh -l -a debug --no-kernel -f test-dracut.img $(shell uname -r)
	@echo wrote  test-dracut.img 

hostimage: all
	./dracut.sh -H -l -a debug -f test-$(shell uname -r).img $(shell uname -r)
	@echo wrote  test-$(shell uname -r).img 

AUTHORS:
	git shortlog  --numbered --summary -e |while read a rest; do echo $$rest;done > AUTHORS
