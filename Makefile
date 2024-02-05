-include dracut-version.sh

DRACUT_MAIN_VERSION ?= $(shell env GIT_CEILING_DIRECTORIES=$(CURDIR)/.. git describe --abbrev=0 --tags --always 2>/dev/null || :)
ifeq ($(DRACUT_MAIN_VERSION),)
DRACUT_MAIN_VERSION = $(DRACUT_VERSION)
endif
DRACUT_FULL_VERSION ?= $(shell env GIT_CEILING_DIRECTORIES=$(CURDIR)/.. git describe --tags --always 2>/dev/null || :)
ifeq ($(DRACUT_FULL_VERSION),)
DRACUT_FULL_VERSION = $(DRACUT_VERSION)
endif

HAVE_SHELLCHECK ?= $(shell command -v shellcheck >/dev/null 2>&1 && echo yes)
HAVE_SHFMT ?= $(shell command -v shfmt >/dev/null  2>&1 && echo yes)

-include Makefile.inc

KVERSION ?= $(shell uname -r)

prefix ?= /usr
libdir ?= ${prefix}/lib
datadir ?= ${prefix}/share
pkglibdir ?= ${libdir}/dracut
sysconfdir ?= ${prefix}/etc
bindir ?= ${prefix}/bin
mandir ?= ${prefix}/share/man
CFLAGS ?= -O2 -g -Wall -std=gnu99 -D_FILE_OFFSET_BITS=64 -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2
bashcompletiondir ?= ${datadir}/bash-completion/completions
pkgconfigdatadir ?= $(datadir)/pkgconfig

man1pages = man/lsinitrd.1

man5pages = man/dracut.conf.5

man7pages = man/dracut.cmdline.7 \
            man/dracut.bootup.7 \
            man/dracut.modules.7

man8pages = man/dracut.8 \
            man/dracut-catimages.8 \
            modules.d/98dracut-systemd/dracut-cmdline.service.8 \
            modules.d/98dracut-systemd/dracut-initqueue.service.8 \
            modules.d/98dracut-systemd/dracut-mount.service.8 \
            modules.d/98dracut-systemd/dracut-shutdown.service.8 \
            modules.d/98dracut-systemd/dracut-pre-mount.service.8 \
            modules.d/98dracut-systemd/dracut-pre-pivot.service.8 \
            modules.d/98dracut-systemd/dracut-pre-trigger.service.8 \
            modules.d/98dracut-systemd/dracut-pre-udev.service.8

manpages = $(man1pages) $(man5pages) $(man7pages) $(man8pages)

.PHONY: install clean archive testimage test all check AUTHORS CONTRIBUTORS doc

all: dracut.pc dracut-install src/skipcpio/skipcpio dracut-util

%.o : %.c
	$(CC) -c $(CFLAGS) $(CPPFLAGS) $(KMOD_CFLAGS) $< -o $@

DRACUT_INSTALL_OBJECTS = \
        src/install/dracut-install.o \
        src/install/hashmap.o\
        src/install/log.o \
        src/install/strv.o \
        src/install/util.o

# deps generated with gcc -MM
src/install/dracut-install.o: src/install/dracut-install.c src/install/log.h src/install/macro.h \
	src/install/hashmap.h src/install/util.h
src/install/hashmap.o: src/install/hashmap.c src/install/util.h src/install/macro.h src/install/log.h \
	src/install/hashmap.h
src/install/log.o: src/install/log.c src/install/log.h src/install/macro.h src/install/util.h
src/install/util.o: src/install/util.c src/install/util.h src/install/macro.h src/install/log.h
src/install/strv.o: src/install/strv.c src/install/strv.h src/install/util.h src/install/macro.h src/install/log.h

src/install/dracut-install: $(DRACUT_INSTALL_OBJECTS)
	$(CC) $(LDFLAGS) -o $@ $(DRACUT_INSTALL_OBJECTS) $(LDLIBS) $(FTS_LIBS) $(KMOD_LIBS)

logtee: src/logtee/logtee.c
	$(CC) $(LDFLAGS) -o $@ $<

dracut-install: src/install/dracut-install
	ln -fs $< $@

SKIPCPIO_OBJECTS = src/skipcpio/skipcpio.o
skipcpio/skipcpio.o: src/skipcpio/skipcpio.c
skipcpio/skipcpio: $(SKIPCPIO_OBJECTS)

UTIL_OBJECTS = src/util/util.o
util/util.o: src/util/util.c
util/util: $(UTIL_OBJECTS)

dracut-util: src/util/util
	cp -a $< $@

.PHONY: indent-c
indent-c:
	astyle -n --quiet --options=.astylerc $(wildcard *.[ch] */*.[ch] src/*/*.[ch])

.PHONY: indent
indent: indent-c
ifeq ($(HAVE_SHFMT),yes)
	shfmt -w -s .
endif

src/dracut-cpio/target/release/dracut-cpio: src/dracut-cpio/src/main.rs
	cargo --offline build --release --manifest-path src/dracut-cpio/Cargo.toml

dracut-cpio: src/dracut-cpio/target/release/dracut-cpio
	ln -fs $< $@

ifeq ($(enable_dracut_cpio),yes)
all: dracut-cpio
endif

doc: $(manpages) dracut.html

ifneq ($(enable_documentation),no)
all: doc
endif

%: %.xml
	@rm -f -- "$@"
	xsltproc -o "$@" -nonet http://docbook.sourceforge.net/release/xsl/current/manpages/docbook.xsl $<

%.xml: %.asc
	@rm -f -- "$@"
	asciidoc -a "version=$(DRACUT_FULL_VERSION)" -d manpage -b docbook -o "$@" $<

dracut.8: man/dracut.8.asc \
	man/dracut.usage.asc

dracut.html: man/dracut.asc $(manpages) docs/dracut.css man/dracut.usage.asc
	@rm -f -- dracut.xml
	asciidoc -a "mainversion=$(DRACUT_MAIN_VERSION)" \
		-a "version=$(DRACUT_FULL_VERSION)" \
		-a numbered \
		-d book -b docbook -o dracut.xml man/dracut.asc
	@rm -f -- dracut.html
	xsltproc -o dracut.html --xinclude -nonet \
		--stringparam custom.css.source docs/dracut.css \
		--stringparam generate.css.header 1 \
		http://docbook.sourceforge.net/release/xsl/current/xhtml/docbook.xsl dracut.xml
	@rm -f -- dracut.xml

dracut.pc: Makefile.inc Makefile
	@echo "Name: dracut" > dracut.pc
	@echo "Description: dracut" >> dracut.pc
	@echo "Version: $(DRACUT_FULL_VERSION)" >> dracut.pc
	@echo "dracutdir=$(pkglibdir)" >> dracut.pc
	@echo "dracutmodulesdir=$(pkglibdir)/modules.d" >> dracut.pc
	@echo "dracutconfdir=$(pkglibdir)/dracut.conf.d" >> dracut.pc

install: all
	mkdir -p $(DESTDIR)$(pkglibdir)
	mkdir -p $(DESTDIR)$(bindir)
	mkdir -p $(DESTDIR)$(sysconfdir)
	mkdir -p $(DESTDIR)$(pkglibdir)/modules.d
	mkdir -p $(DESTDIR)$(mandir)/man1 $(DESTDIR)$(mandir)/man5 $(DESTDIR)$(mandir)/man7 $(DESTDIR)$(mandir)/man8
	install -m 0755 dracut.sh $(DESTDIR)$(bindir)/dracut
	install -m 0755 dracut-catimages.sh $(DESTDIR)$(bindir)/dracut-catimages
	install -m 0755 lsinitrd.sh $(DESTDIR)$(bindir)/lsinitrd
	install -m 0644 dracut.conf $(DESTDIR)$(sysconfdir)/dracut.conf
	mkdir -p $(DESTDIR)$(sysconfdir)/dracut.conf.d
	mkdir -p $(DESTDIR)$(pkglibdir)/dracut.conf.d
	install -m 0755 dracut-init.sh $(DESTDIR)$(pkglibdir)/dracut-init.sh
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
		ln -srf $(DESTDIR)$(pkglibdir)/modules.d/98dracut-systemd/dracut-shutdown-onfailure.service $(DESTDIR)$(systemdsystemunitdir)/dracut-shutdown-onfailure.service; \
		ln -srf $(DESTDIR)$(pkglibdir)/modules.d/98dracut-systemd/dracut-shutdown.service $(DESTDIR)$(systemdsystemunitdir)/dracut-shutdown.service; \
		mkdir -p $(DESTDIR)$(systemdsystemunitdir)/sysinit.target.wants; \
		ln -s ../dracut-shutdown.service \
		$(DESTDIR)$(systemdsystemunitdir)/sysinit.target.wants/dracut-shutdown.service; \
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
			ln -srf $(DESTDIR)$(pkglibdir)/modules.d/98dracut-systemd/$$i $(DESTDIR)$(systemdsystemunitdir); \
			ln -s ../$$i \
			$(DESTDIR)$(systemdsystemunitdir)/initrd.target.wants/$$i; \
		done \
	fi
	if [ -f src/install/dracut-install ]; then \
		install -m 0755 src/install/dracut-install $(DESTDIR)$(pkglibdir)/dracut-install; \
	fi
	if [ -f src/skipcpio/skipcpio ]; then \
		install -m 0755 src/skipcpio/skipcpio $(DESTDIR)$(pkglibdir)/skipcpio; \
	fi
	if [ -f dracut-util ]; then \
		install -m 0755 dracut-util $(DESTDIR)$(pkglibdir)/dracut-util; \
	fi
ifeq ($(enable_dracut_cpio),yes)
	install -m 0755 dracut-cpio $(DESTDIR)$(pkglibdir)/dracut-cpio
endif
	mkdir -p $(DESTDIR)${prefix}/lib/kernel/install.d
	install -m 0755 install.d/50-dracut.install $(DESTDIR)${prefix}/lib/kernel/install.d/50-dracut.install
	install -m 0755 install.d/51-dracut-rescue.install $(DESTDIR)${prefix}/lib/kernel/install.d/51-dracut-rescue.install
	mkdir -p $(DESTDIR)${bashcompletiondir}
	install -m 0644 shell-completion/bash/dracut $(DESTDIR)${bashcompletiondir}/dracut
	install -m 0644 shell-completion/bash/lsinitrd $(DESTDIR)${bashcompletiondir}/lsinitrd
	mkdir -p $(DESTDIR)${pkgconfigdatadir}
	install -m 0644 dracut.pc $(DESTDIR)${pkgconfigdatadir}/dracut.pc

clean:
	$(RM) *~
	$(RM) */*~
	$(RM) */*/*~
	$(RM) $(manpages:%=%.xml) dracut.xml
	$(RM) test-*.img
	$(RM) dracut-*.tar.bz2 dracut-*.tar.xz
	$(RM) dracut-install src/install/dracut-install $(DRACUT_INSTALL_OBJECTS)
	$(RM) skipcpio/skipcpio $(SKIPCPIO_OBJECTS)
	$(RM) dracut-util util/util $(UTIL_OBJECTS)
	$(RM) $(manpages) dracut.html
	$(RM) dracut.pc
	$(RM) dracut-cpio src/dracut-cpio/target/release/dracut-cpio*
	$(MAKE) -C test clean

dist: dracut-$(DRACUT_MAIN_VERSION).tar.xz

dracut-$(DRACUT_MAIN_VERSION).tar.xz: doc syncheck
	git archive --format=tar $(DRACUT_MAIN_VERSION) --prefix=dracut-$(DRACUT_MAIN_VERSION)/ > dracut-$(DRACUT_MAIN_VERSION).tar
	mkdir -p dracut-$(DRACUT_MAIN_VERSION)
	for i in $(manpages) dracut.html; do [ "$${i%/*}" != "$$i" ] && mkdir -p "dracut-$(DRACUT_MAIN_VERSION)/$${i%/*}"; cp "$$i" "dracut-$(DRACUT_MAIN_VERSION)/$$i"; done
	tar --owner=root --group=root -rf dracut-$(DRACUT_MAIN_VERSION).tar $$(find dracut-$(DRACUT_MAIN_VERSION) -type f)
	rm -fr -- dracut-$(DRACUT_MAIN_VERSION).tar.xz dracut-$(DRACUT_MAIN_VERSION)
	xz -9 dracut-$(DRACUT_MAIN_VERSION).tar
	rm -f -- dracut-$(DRACUT_MAIN_VERSION).tar

syncheck:
	@ret=0;for i in dracut-initramfs-restore.sh modules.d/*/*.sh; do \
                [ "$${i##*/}" = "module-setup.sh" ] && continue; \
                read line < "$$i"; [ "$${line#*bash*}" != "$$line" ] && continue; \
		[ $$V ] && echo "posix syntax check: $$i"; bash --posix -n "$$i" ; ret=$$(($$ret+$$?)); \
		[ $$V ] && echo "checking for [[: $$i"; if grep -Fq '[[ ' "$$i" ; then ret=$$(($$ret+1)); echo "$$i contains [["; fi; \
		[ $$V ] && echo "checking for echo -n: $$i"; if grep -Fq 'echo -n ' "$$i" ; then ret=$$(($$ret+1)); echo "$$i contains echo -n"; fi \
	done;exit $$ret
	@ret=0;for i in *.sh modules.d/*/*.sh modules.d/*/module-setup.sh; do \
		[ $$V ] && echo "bash syntax check: $$i"; bash -n "$$i" ; ret=$$(($$ret+$$?)); \
	done;exit $$ret
ifeq ($(HAVE_SHELLCHECK),yes)
ifeq ($(HAVE_SHFMT),yes)
	shellcheck $$(shfmt -f .)
else
	find . -name '*.sh' -print0 | xargs -0 shellcheck
endif
endif

check: all syncheck
	@$(MAKE) -C test check

testimage: all
	./dracut.sh -N -l -a debug -f test-$(KVERSION).img $(KVERSION)
	@echo wrote  test-$(KVERSION).img

debugtestimage: all
	./dracut.sh --debug -l -a debug -f test-$(KVERSION).img $(KVERSION)
	@echo wrote  test-$(KVERSION).img

testimages: all
	./dracut.sh -l -a debug --kernel-only -f test-kernel-$(KVERSION).img $(KVERSION)
	@echo wrote  test-$(KVERSION).img
	./dracut.sh -l -a debug --no-kernel -f test-dracut.img $(KVERSION)
	@echo wrote  test-dracut.img

debughostimage: all
	./dracut.sh --debug -H -l -f test-$(KVERSION).img $(KVERSION)
	@echo wrote  test-$(KVERSION).img

hostimage: all
	./dracut.sh -H -l -f test-$(KVERSION).img $(KVERSION)
	@echo wrote  test-$(KVERSION).img

efi: all
	./dracut.sh --uefi -H -l -f linux-$(KVERSION).efi $(KVERSION)
	@echo wrote linux-$(KVERSION).efi

AUTHORS:
	@git log | git shortlog --numbered --summary -e | while read -r a rest || [ -n "$$rest" ]; do echo "$$rest"; done > AUTHORS

CONTRIBUTORS:
	@git log | git shortlog $(DRACUT_MAIN_VERSION).. --numbered --summary -e | while read -r a rest || [ -n "$$rest" ]; do echo "- $$rest"; done
