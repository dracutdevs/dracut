#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh

mount_root() {
    rootfs="aufs"
    rflags="br=${aufsrwbranch}:${aufsrobranch},${aufsoptions}"

    modprobe aufs

    mount -t ${rootfs} -o "$rflags" none "$NEWROOT"

    [ -f "$NEWROOT"/forcefsck ] && rm -f "$NEWROOT"/forcefsck 2>/dev/null
    [ -f "$NEWROOT"/.autofsck ] && rm -f "$NEWROOT"/.autofsck 2>/dev/null
}

if [ -n "$root" -a -z "${root%%aufs:*}" ]; then
    mount_root
fi
:
