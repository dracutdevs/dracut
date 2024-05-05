#!/bin/sh

# Remove leftover udev control socket to prevent cryptsetup hangup
rm -f /run/udev/control

# Mark crypt devices for deferred removal.
# The dm module removes holding devices, so
# that the encryption keys can be released.
dmsetup ls --target crypt | while read -r name _; do
    if ! type "cryptsetup" > /dev/null 2>&1; then
        systemd-cryptsetup detach "$name" deferred 2>&1 | vinfo
    else
        cryptsetup close "$name" --deferred 2>&1 | vinfo
    fi
done
