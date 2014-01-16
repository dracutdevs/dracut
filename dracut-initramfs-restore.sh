#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

set -e

KERNEL_VERSION="$(uname -r)"

[[ -f /etc/machine-id ]] && read MACHINE_ID < /etc/machine-id

if [[ $MACHINE_ID ]] && [[ -d /boot/${MACHINE_ID} || -L /boot/${MACHINE_ID} ]] ; then
    IMG="/boot/${MACHINE_ID}/${KERNEL_VERSION}/initrd"
fi
[[ -f $IMG ]] || IMG="/boot/initramfs-${KERNEL_VERSION}.img"

cd /run/initramfs

[ -f .need_shutdown -a -f "$IMG" ] || exit 1
if zcat "$IMG"  | cpio -id --quiet >/dev/null; then
    rm -f -- .need_shutdown
elif xzcat "$IMG"  | cpio -id --quiet >/dev/null; then
    rm -f -- .need_shutdown
elif lz4 -d -c "$IMG"  | cpio -id --quiet >/dev/null; then
    rm -f -- .need_shutdown
else
    # something failed, so we clean up
    echo "Unpacking of $IMG to /run/initramfs failed" >&2
    rm -f -- /run/initramfs/shutdown
    exit 1
fi

exit 0
