all:
	@echo "Nothing to do"

install:
	mkdir -p $(DESTDIR)/usr/libexec/dracut
	mkdir -p $(DESTDIR)/sbin
	mkdir -p $(DESTDIR)/usr/libexec/dracut/modules.d
	install -m 0755 dracut $(DESTDIR)/sbin/dracut
	install -m 0755 dracut-functions $(DESTDIR)/usr/libexec/dracut/functions
	for module in modules/*/*; do install -D -m 0755 $$module $(DESTDIR)/usr/libexec/dracut/modules.d ; done
clean:
	rm -f *~

archive:
	git archive --format=tar HEAD --prefix=dracut/ |bzip2 > dracut-$(shell git rev-list  --abbrev-commit  -n 1 HEAD  |cut -b 1-8).tar.bz2
