.PHONY: all check clean

check:
	@for i in TEST-[0-9]*; do \
		[ -d $$i ] || continue ; \
		[ -f $$i/Makefile ] || continue ; \
		if [ -n "$$TESTS" ]; then t=$${i##TEST-}; t=$${t%-*}; [ "$${TESTS#*$$t*}" != "$$TESTS" ] || continue; fi; \
		$(MAKE) -C $$i all ; \
	done

clean:
	@for i in TEST-[0-9]*; do \
		[ -d $$i ] || continue ; \
		[ -f $$i/Makefile ] || continue ; \
		$(MAKE) -C $$i clean ; \
	done

all:

