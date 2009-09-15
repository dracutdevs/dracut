#!/bin/sh

if ! getarg rd_NO_PLYMOUTH; then
    [ -c /dev/null ] || mknod /dev/null c 1 3
    # first trigger graphics subsystem
    udevadm trigger --attr-match=class=0x030000 >/dev/null 2>&1
    # first trigger graphics and tty subsystem
    udevadm trigger --subsystem-match=graphics --subsystem-match=drm --subsystem-match=tty >/dev/null 2>&1

    udevadm settle --timeout=30 2>&1 | vinfo
    [ -c /dev/zero ] || mknod /dev/zero c 1 5
    [ -c /dev/systty ] || mknod /dev/systty c 4 0
    [ -c /dev/fb ] || mknod /dev/fb c 29 0
    [ -c /dev/hvc0 ] || mknod /dev/hvc0 c 229 0

    info "Starting plymouth daemon"
    [ -x /bin/plymouthd ] && /bin/plymouthd --attach-to-session
    /bin/plymouth --show-splash 2>&1 | vinfo
fi


# vim:ts=8:sw=4:sts=4:et
