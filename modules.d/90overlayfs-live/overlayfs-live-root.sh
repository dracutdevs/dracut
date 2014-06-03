#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh

PATH=/usr/sbin:/usr/bin:/sbin:/bin

if getargbool 0 rd.live.debug -n -y rdlivedebug; then
    exec > /tmp/liveroot.$$.out
    exec 2>> /tmp/liveroot.$$.out
    set -x
fi

[ -z "$1" ] && exit 1
livedev="$1"

ln -sf $livedev /run/initramfs/livedev

modprobe squashfs
CMDLINE=$(getcmdline)
for arg in $CMDLINE; do case $arg in ro|rw) liverw=$arg ;; esac; done
mkdir -m 0755 -p /run/initramfs/live-ro /run/initramfs/live-rw
mount -n -t auto $livedev /run/initramfs/live-ro
mount -n -t tmpfs tmpfs -o $rootflags /run/initramfs/live-rw
mount -n -t overlayfs overlayfs -o $rootflags,upperdir=/run/initramfs/live-rw,lowerdir=/run/initramfs/live-ro "$NEWROOT"

ROOTFLAGS="$(getarg rootflags)"
if [ -n "$ROOTFLAGS" ]; then
    ROOTFLAGS="-o $ROOTFLAGS"
fi

exit 0
