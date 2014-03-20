#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

set -e

KERNEL_VERSION="$(uname -r)"

[[ $dracutbasedir ]] || dracutbasedir=/usr/lib/dracut
SKIP="$dracutbasedir/skipcpio"
[[ -x $SKIP ]] || SKIP=cat

[[ -f /etc/machine-id ]] && read MACHINE_ID < /etc/machine-id

if [[ $MACHINE_ID ]] && [[ -d /boot/${MACHINE_ID} || -L /boot/${MACHINE_ID} ]] ; then
    IMG="/boot/${MACHINE_ID}/${KERNEL_VERSION}/initrd"
fi
[[ -f $IMG ]] || IMG="/boot/initramfs-${KERNEL_VERSION}.img"

cd /run/initramfs

[ -f .need_shutdown -a -f "$IMG" ] || exit 1
if $SKIP "$IMG" | zcat | cpio -id --no-absolute-filenames --quiet >/dev/null; then
    rm -f -- .need_shutdown
elif $SKIP "$IMG" | xzcat | cpio -id --no-absolute-filenames --quiet >/dev/null; then
    rm -f -- .need_shutdown
elif $SKIP "$IMG" | lz4 -d -c | cpio -id --no-absolute-filenames --quiet >/dev/null; then
    rm -f -- .need_shutdown
else
    # something failed, so we clean up
    echo "Unpacking of $IMG to /run/initramfs failed" >&2
    rm -f -- /run/initramfs/shutdown
    exit 1
fi

exit 0
