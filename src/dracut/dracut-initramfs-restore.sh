#!/bin/bash

set -e

# do some sanity checks first
[ -e /run/initramfs/bin/sh ] && exit 0
[ -e /run/initramfs/.need_shutdown ] || exit 0

KERNEL_VERSION="$(uname -r)"

[[ $dracutbasedir ]] || dracutbasedir=/usr/lib/dracut
SKIP="$dracutbasedir/skipcpio"
[[ -x $SKIP ]] || SKIP="cat"

[[ -f /etc/machine-id ]] && read -r MACHINE_ID < /etc/machine-id

mount -o ro /boot &> /dev/null || true

if [[ -d /efi/loader/entries || -L /efi/loader/entries ]] \
    && [[ $MACHINE_ID ]] \
    && [[ -d /efi/${MACHINE_ID} || -L /efi/${MACHINE_ID} ]]; then
    IMG="/efi/${MACHINE_ID}/${KERNEL_VERSION}/initrd"
elif [[ -d /boot/loader/entries || -L /boot/loader/entries ]] \
    && [[ $MACHINE_ID ]] \
    && [[ -d /boot/${MACHINE_ID} || -L /boot/${MACHINE_ID} ]]; then
    IMG="/boot/${MACHINE_ID}/${KERNEL_VERSION}/initrd"
elif [[ -f /boot/initramfs-${KERNEL_VERSION}.img ]]; then
    IMG="/boot/initramfs-${KERNEL_VERSION}.img"
elif [[ -f /lib/modules/${KERNEL_VERSION}/initrd ]]; then
    IMG="/lib/modules/${KERNEL_VERSION}/initrd"
else
    echo "No initramfs image found to restore!"
    exit 1
fi

cd /run/initramfs

if $SKIP "$IMG" | zcat | cpio -id --no-absolute-filenames --quiet > /dev/null; then
    rm -f -- .need_shutdown
elif $SKIP "$IMG" | xzcat | cpio -id --no-absolute-filenames --quiet > /dev/null; then
    rm -f -- .need_shutdown
elif $SKIP "$IMG" | lz4 -d -c | cpio -id --no-absolute-filenames --quiet > /dev/null; then
    rm -f -- .need_shutdown
elif $SKIP "$IMG" | zstd -d -c | cpio -id --no-absolute-filenames --quiet > /dev/null; then
    rm -f -- .need_shutdown
else
    # something failed, so we clean up
    echo "Unpacking of $IMG to /run/initramfs failed" >&2
    rm -f -- /run/initramfs/shutdown
    exit 1
fi

if [[ -d squash ]]; then
    if ! unsquashfs -no-xattrs -f -d . squash-root.img > /dev/null; then
        echo "Squash module is enabled for this initramfs but failed to unpack squash-root.img" >&2
        rm -f -- /run/initramfs/shutdown
        exit 1
    fi
fi

if [ -e /etc/selinux/config -a -x /usr/sbin/setfiles ]; then
    . /etc/selinux/config
    /usr/sbin/setfiles -v -r /run/initramfs /etc/selinux/"${SELINUXTYPE}"/contexts/files/file_contexts /run/initramfs > /dev/null
fi

exit 0
