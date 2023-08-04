#!/bin/sh

# Mark crypt devices for deferred removal.
# The dm module removes holding devices, so
# that the encryption keys can be released.
dmsetup ls --target crypt | while read -r name _; do
    if ! type "cryptsetup" > /dev/null 2>&1; then
        warn "cryptsetup not installed, skipping closing of encrypted devices"
        return
    fi
    cryptsetup close "$name" --deferred 2>&1 | vinfo
done
