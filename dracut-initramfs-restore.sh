#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

set -e
cd /run/initramfs
IMG="/boot/initramfs-$(uname -r).img"
[ -f .need_shutdown -a -f "$IMG" ] || exit 1
if zcat "$IMG"  | cpio -id >/dev/null 2>&1; then
    rm .need_shutdown
elif xzcat "$IMG"  | cpio -id >/dev/null 2>&1; then
    rm .need_shutdown
else
    # something failed, so we clean up
    rm -f /run/initramfs/shutdown
    exit 1
fi

exit 0
