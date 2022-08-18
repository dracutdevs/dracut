#!/bin/bash

for i in \
    sysinit.target \
    basic.target \
    initrd-fs.target \
    initrd.target \
    initrd-switch-root.target \
    emergency.target \
    shutdown.target; do
    if ! systemd-analyze verify "$i"; then
        warn "systemd-analyze verify $i failed"
        poweroff
    fi
done
