RELEASEDVERSION = -- will be replaced by "make dist" --
VERSION = $(shell [ -d .git ] && git describe --abbrev=0 --tags || echo $(RELEASEDVERSION))
GITVERSION = $(shell [ -d .git ] && { v=$$(git describe --tags); echo -$${v\#*-}; } )

-include Makefile.inc

prefix ?= /usr
libdir ?= ${prefix}/lib
datadir ?= ${prefix}/share
pkglibdir ?= ${libdir}/dracut
sysconfdir ?= ${prefix}/etc
bindir ?= ${prefix}/bin
mandir ?= ${prefix}/share/man
CFLAGS ?= -O2 -g -Wall
CFLAGS += -std=gnu99  -D_FILE_OFFSET_BITS=64
bashcompletiondir ?= ${datadir}/bash-completion/completions

man1pages = lsinitrd.1

man5pages = dracut.conf.5

man7pages = dracut.cmdline.7 \
            dracut.bootup.7

man8pages = dracut.8 \
            dracut-catimages.8 \
            mkinitrd.8 \
            modules.d/98systemd/dracut-cmdline.service.8 \
            modules.d/98systemd/dracut-initqueue.service.8 \
            modules.d/98systemd/dracut-mount.service.8 \
            modules.d/98systemd/dracut-pre-mount.service.8 \
            modules.d/98systemd/dracut-pre-pivot.service.8 \
            modules.d/98systemd/dracut-pre-trigger.service.8 \
            modules.d/98systemd/dracut-pre-udev.service.8

manpages = $(man1pages) $(man5pages) $(man7pages) $(man8pages)


.PHONY: install clean archive rpm testimage test all check AUTHORS doc dracut-version.sh

all: syncheck dracut-version.sh dracut-install

DRACUT_INSTALL_OBJECTS = \
        install/dracut-install.o \
        install/hashmap.o\
        install/log.o \
        install/util.o

# deps generated with gcc -MM
install/dracut-install.o: install/dracut-install.c install/log.h install/macro.h \
	install/hashmap.h install/util.h
install/hashmap.o: install/hashmap.c install/util.h install/macro.h install/log.h \
	install/hashmap.h
install/log.o: install/log.c install/log.h install/macro.h install/util.h
install/util.o: install/util.c install/util.h install/macro.h install/log.h

install/dracut-install: $(DRACUT_INSTALL_OBJECTS)

dracut-install: install/dracut-install
	ln -fs $< $@

indent:
	indent -i8 -nut -br -linux -l120 install/dracut-install.c

doc: $(manpages) dracut.html

ifneq ($(enable_documentation),no)
all: doc
endif

%: %.xml
	xsltproc -o $@ -nonet http://docbook.sourceforge.net/release/xsl/current/manpages/docbook.xsl $<

%.xml: %.asc
	asciidoc -d manpage -b docbook -o $@ $<

dracut.html: dracut.asc $(manpages)
	asciidoc -a numbered -d book -b docbook -o dracut.xml dracut.asc
	xsltproc -o dracut.html --xinclude -nonet \
		--stringparam html.stylesheet \
		http://docs.fedoraproject.org/en-US/Common_Content/css/default.css \
		http://docbook.sourceforge.net/release/xsl/current/xhtml/docbook.xsl dracut.xml
	rm dracut.xml

install: dracut-version.sh
	mkdir -p $(DESTDIR)$(pkglibdir)
	mkdir -p $(DESTDIR)$(bindir)
	mkdir -p $(DESTDIR)$(sysconfdir)
	mkdir -p $(DESTDIR)$(pkglibdir)/modules.d
	mkdir -p $(DESTDIR)$(mandir)/man1 $(DESTDIR)$(mandir)/man5 $(DESTDIR)$(mandir)/man7 $(DESTDIR)$(mandir)/man8
	install -m 0755 dracut.sh $(DESTDIR)$(bindir)/dracut
	install -m 0755 dracut-catimages.sh $(DESTDIR)$(bindir)/dracut-catimages
	install -m 0755 mkinitrd-dracut.sh $(DESTDIR)$(bindir)/mkinitrd
	install -m 0755 lsinitrd.sh $(DESTDIR)$(bindir)/lsinitrd
	install -m 0644 dracut.conf $(DESTDIR)$(sysconfdir)/dracut.conf
	mkdir -p $(DESTDIR)$(sysconfdir)/dracut.conf.d
	mkdir -p $(DESTDIR)$(pkglibdir)/dracut.conf.d
	install -m 0755 dracut-functions.sh $(DESTDIR)$(pkglibdir)/dracut-functions.sh
	install -m 0755 dracut-version.sh $(DESTDIR)$(pkglibdir)/dracut-version.sh
	ln -fs dracut-functions.sh $(DESTDIR)$(pkglibdir)/dracut-functions
	install -m 0755 dracut-logger.sh $(DESTDIR)$(pkglibdir)/dracut-logger.sh
	install -m 0755 dracut-initramfs-restore.sh $(DESTDIR)$(pkglibdir)/dracut-initramfs-restore
	cp -arx modules.d $(DESTDIR)$(pkglibdir)
ifneq ($(enable_documentation),no)
	for i in $(man1pages); do install -m 0644 $$i $(DESTDIR)$(mandir)/man1/$${i##*/}; done
	for i in $(man5pages); do install -m 0644 $$i $(DESTDIR)$(mandir)/man5/$${i##*/}; done
	for i in $(man7pages); do install -m 0644 $$i $(DESTDIR)$(mandir)/man7/$${i##*/}; done
	for i in $(man8pages); do install -m 0644 $$i $(DESTDIR)$(mandir)/man8/$${i##*/}; done
	ln -fs dracut.cmdline.7 $(DESTDIR)$(mandir)/man7/dracut.kernel.7
endif
	if [ -n "$(systemdsystemunitdir)" ]; then \
		mkdir -p $(DESTDIR)$(systemdsystemunitdir); \
		install -m 0644 dracut-shutdown.service $(DESTDIR)$(systemdsystemunitdir); \
		mkdir -p $(DESTDIR)$(systemdsystemunitdir)/shutdown.target.wants; \
		ln -s ../dracut-shutdown.service \
		$(DESTDIR)$(systemdsystemunitdir)/shutdown.target.wants/dracut-shutdown.service; \
		mkdir -p $(DESTDIR)$(systemdsystemunitdir)/initrd.target.wants; \
		for i in \
		    dracut-cmdline.service \
		    dracut-initqueue.service \
		    dracut-mount.service \
		    dracut-pre-mount.service \
		    dracut-pre-pivot.service \
		    dracut-pre-trigger.service \
		    dracut-pre-udev.service \
		    ; do \
			ln -srf $(DESTDIR)$(pkglibdir)/modules.d/98systemd/$$i $(DESTDIR)$(systemdsystemunitdir); \
			ln -s ../$$i \
			$(DESTDIR)$(systemdsystemunitdir)/initrd.target.wants/$$i; \
		done \
	fi
	if [ -f install/dracut-install ]; then \
		install -m 0755 install/dracut-install $(DESTDIR)$(pkglibdir)/dracut-install; \
	fi
	mkdir -p $(DESTDIR)${prefix}/lib/kernel/install.d
	install -m 0755 50-dracut.install $(DESTDIR)${prefix}/lib/kernel/install.d/50-dracut.install
	install -m 0755 51-dracut-rescue.install $(DESTDIR)${prefix}/lib/kernel/install.d/51-dracut-rescue.install
	mkdir -p $(DESTDIR)${bashcompletiondir}
	install -m 0644 dracut-bash-completion.sh $(DESTDIR)${bashcompletiondir}/dracut
	install -m 0644 lsinitrd-bash-completion.sh $(DESTDIR)${bashcompletiondir}/lsinitrd

dracut-version.sh:
	@echo "DRACUT_VERSION=$(VERSION)$(GITVERSION)" > dracut-version.sh

clean:
	$(RM) *~
	$(RM) */*~
	$(RM) */*/*~
	$(RM) $(manpages:%=%.xml) dracut.xml
	$(RM) test-*.img
	$(RM) dracut-*.rpm dracut-*.tar.bz2
	$(RM) dracut-version.sh
	$(RM) dracut-install install/dracut-install $(DRACUT_INSTALL_OBJECTS)
	$(RM) $(manpages) dracut.html
	$(MAKE) -C test clean

dist: dracut-$(VERSION).tar.bz2

dracut-$(VERSION).tar.bz2: doc
	git archive --format=tar $(VERSION) --prefix=dracut-$(VERSION)/ > dracut-$(VERSION).tar
	mkdir -p dracut-$(VERSION)
	cp $(manpages) dracut.html dracut-$(VERSION)
	git show $(VERSION):Makefile | sed 's/^RELEASEDVERSION =.*/RELEASEDVERSION = $(VERSION)/' > dracut-$(VERSION)/Makefile
	tar --owner=root --group=root -rf dracut-$(VERSION).tar dracut-$(VERSION)/*.[0-9] dracut-$(VERSION)/dracut.html dracut-$(VERSION)/Makefile
	rm -fr dracut-$(VERSION).tar.bz2 dracut-$(VERSION)
	bzip2 -9 dracut-$(VERSION).tar
	rm -f dracut-$(VERSION).tar

rpm: dracut-$(VERSION).tar.bz2
	rpmbuild=$$(mktemp -d -t rpmbuild-dracut.XXXXXX); src=$$(pwd); \
	cp dracut-$(VERSION).tar.bz2 "$$rpmbuild"; \
	LC_MESSAGES=C $$src/git2spec.pl $(VERSION) "$$rpmbuild" < dracut.spec > $$rpmbuild/dracut.spec; \
	(cd "$$rpmbuild"; rpmbuild --define "_topdir $$PWD" --define "_sourcedir $$PWD" \
	        --define "_specdir $$PWD" --define "_srcrpmdir $$PWD" \
		--define "_rpmdir $$PWD" -ba dracut.spec; ) && \
	( mv "$$rpmbuild"/$$(arch)/*.rpm .; mv "$$rpmbuild"/*.src.rpm .;rm -fr "$$rpmbuild"; ls *.rpm )

syncheck:
	@ret=0;for i in dracut-initramfs-restore.sh dracut-logger.sh \
                        modules.d/99base/init.sh modules.d/*/*.sh; do \
                [ "$${i##*/}" = "module-setup.sh" ] && continue; \
                read line < "$$i"; [ "$${line#*bash*}" != "$$line" ] && continue; \
		[ $$V ] && echo "dash syntax check: $$i"; dash -n "$$i" ; ret=$$(($$ret+$$?)); \
	done;exit $$ret
	@ret=0;for i in *.sh mkinitrd-dracut.sh modules.d/*/*.sh \
	                modules.d/*/module-setup.sh; do \
		[ $$V ] && echo "bash syntax check: $$i"; bash -n "$$i" ; ret=$$(($$ret+$$?)); \
	done;exit $$ret

check: all syncheck rpm
	@[ "$$EUID" == "0" ] || { echo "'check' must be run as root! Please use 'sudo'."; exit 1; }
	@$(MAKE) -C test check

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

dracut.html.sign: dracut-$(VERSION).tar.bz2
	gpg-sign-all dracut-$(VERSION).tar.bz2 dracut.html

upload: dracut.html.sign
	kup put dracut-$(VERSION).tar.bz2 dracut-$(VERSION).tar.sign /pub/linux/utils/boot/dracut/
	kup put dracut.html dracut.html.sign /pub/linux/utils/boot/dracut/
