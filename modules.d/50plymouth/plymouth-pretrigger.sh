#!/bin/sh

if ! getarg rd_NO_PLYMOUTH; then
    [ -c /dev/null ] || mknod -m 0666 /dev/null c 1 3
    # first trigger graphics subsystem
    udevadm trigger --attr-match=class=0x030000 >/dev/null 2>&1
    # first trigger graphics and tty subsystem
    udevadm trigger --subsystem-match=graphics --subsystem-match=drm --subsystem-match=tty >/dev/null 2>&1

    udevadm settle --timeout=30 2>&1 | vinfo
    [ -c /dev/zero ] || mknod -m 0666 /dev/zero c 1 5
    [ -c /dev/tty0 ] || mknod -m 0620 /dev/tty0 c 4 0
    [ -e /dev/systty ] || ln -s tty0 /dev/systty
    [ -c /dev/fb0 ] || mknod -m 0660 /dev/fb0 c 29 0
    [ -e /dev/fb ] || ln -s fb0 /dev/fb
    [ -c /dev/hvc0 ] || mknod -m 0600 /dev/hvc0 c 229 0

    info "Starting plymouth daemon"
    [ -x /bin/plymouthd ] && /bin/plymouthd --attach-to-session
    /lib/udev/console_init tty0
    /bin/plymouth --show-splash 2>&1 | vinfo
fi


# vim:ts=8:sw=4:sts=4:et
