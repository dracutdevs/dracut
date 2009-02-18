all:
	@echo "Nothing to do"

install:
	mkdir -p $(DESTDIR)/usr/libexec/dracut
	mkdir -p $(DESTDIR)/sbin
	mkdir -p $(DESTDIR)/usr/libexec/dracut/hooks
	mkdir -p $(DESTDIR)/usr/libexec/dracut/modules
	install -m 0755 dracut $(DESTDIR)/sbin/dracut
	install -m 0755 init $(DESTDIR)/usr/libexec/dracut/init
	install -m 0755 switch_root $(DESTDIR)/usr/libexec/dracut/switch_root
	install -m 0755 dracut-functions $(DESTDIR)/usr/libexec/dracut/functions
	mkdir $(DESTDIR)/usr/libexec/dracut/rules.d
	for rule in rules.d/*.rules ; do install -m 0644 $$rule $(DESTDIR)/usr/libexec/dracut ; done
	for hook in hooks/* ; do install -m 0755 $$hook $(DESTDIR)/usr/libexec/dracut ; done
	for module in modules/*; do install -m 0755 $$module $(DESTDIR)/usr/libexec/dracut ; done
clean:
	rm -f *~

archive:
	git archive --format=tar HEAD --prefix=dracut/ |bzip2 > dracut-$(shell git rev-list  --abbrev-commit  -n 1 HEAD  |cut -b 1-8).tar.bz2
