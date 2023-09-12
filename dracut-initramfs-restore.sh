#!/bin/bash

set -e

# do some sanity checks first
[ -e /run/initramfs/bin/sh ] && exit 0
[ -e /run/initramfs/.need_shutdown ] || exit 0

# SIGTERM signal is received upon forced shutdown: ignore the signal
# We want to remain alive to be able to trap unpacking errors to avoid
# switching root to an incompletely unpacked initramfs
trap 'echo "Received SIGTERM signal, ignoring!" >&2' TERM

KERNEL_VERSION="$(uname -r)"

[[ $dracutbasedir ]] || dracutbasedir=/usr/lib/dracut
SKIP="$dracutbasedir/skipcpio"
[[ -x $SKIP ]] || SKIP="cat"

if [[ -d /efi/Default ]] || [[ -d /boot/Default ]] || [[ -d /boot/efi/Default ]]; then
    MACHINE_ID="Default"
elif [[ -s /etc/machine-id ]]; then
    read -r MACHINE_ID < /etc/machine-id
    [[ $MACHINE_ID == "uninitialized" ]] && MACHINE_ID="Default"
else
    MACHINE_ID="Default"
fi

mount -o ro /boot &> /dev/null || true

if [[ -d /efi/loader/entries || -L /efi/loader/entries ]] \
    && [[ -d /efi/$MACHINE_ID || -L /efi/$MACHINE_ID ]]; then
    IMG="/efi/${MACHINE_ID}/${KERNEL_VERSION}/initrd"
elif [[ -d /boot/loader/entries || -L /boot/loader/entries ]] \
    && [[ -d /boot/$MACHINE_ID || -L /boot/$MACHINE_ID ]]; then
    IMG="/boot/${MACHINE_ID}/${KERNEL_VERSION}/initrd"
elif [[ -d /boot/efi/loader/entries || -L /boot/efi/loader/entries ]] \
    && [[ -d /boot/efi/$MACHINE_ID || -L /boot/efi/$MACHINE_ID ]]; then
    IMG="/boot/efi/$MACHINE_ID/$KERNEL_VERSION/initrd"
elif [[ -f /lib/modules/${KERNEL_VERSION}/initrd ]]; then
    IMG="/lib/modules/${KERNEL_VERSION}/initrd"
elif [[ -f /boot/initramfs-${KERNEL_VERSION}.img ]]; then
    IMG="/boot/initramfs-${KERNEL_VERSION}.img"
elif mountpoint -q /efi; then
    IMG="/efi/$MACHINE_ID/$KERNEL_VERSION/initrd"
elif mountpoint -q /boot/efi; then
    IMG="/boot/efi/$MACHINE_ID/$KERNEL_VERSION/initrd"
else
    echo "No initramfs image found to restore!"
    exit 1
fi

cd /run/initramfs

if (command -v zcat > /dev/null && $SKIP "$IMG" 2> /dev/null | zcat 2> /dev/null | cpio -id --no-absolute-filenames --quiet > /dev/null 2>&1) \
    || (command -v bzcat > /dev/null && $SKIP "$IMG" 2> /dev/null | bzcat 2> /dev/null | cpio -id --no-absolute-filenames --quiet > /dev/null 2>&1) \
    || (command -v xzcat > /dev/null && $SKIP "$IMG" 2> /dev/null | xzcat 2> /dev/null | cpio -id --no-absolute-filenames --quiet > /dev/null 2>&1) \
    || (command -v lz4 > /dev/null && $SKIP "$IMG" 2> /dev/null | lz4 -d -c 2> /dev/null | cpio -id --no-absolute-filenames --quiet > /dev/null 2>&1) \
    || (command -v lzop > /dev/null && $SKIP "$IMG" 2> /dev/null | lzop -d -c 2> /dev/null | cpio -id --no-absolute-filenames --quiet > /dev/null 2>&1) \
    || (command -v zstd > /dev/null && $SKIP "$IMG" 2> /dev/null | zstd -d -c 2> /dev/null | cpio -id --no-absolute-filenames --quiet > /dev/null 2>&1) \
    || ($SKIP "$IMG" 2> /dev/null | cpio -id --no-absolute-filenames --quiet > /dev/null 2>&1); then
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

if grep -q -w selinux /sys/kernel/security/lsm 2> /dev/null \
    && [ -e /etc/selinux/config -a -x /usr/sbin/setfiles ]; then
    . /etc/selinux/config
    if [[ $SELINUX != "disabled" && -n $SELINUXTYPE ]]; then
        /usr/sbin/setfiles -v -r /run/initramfs /etc/selinux/"${SELINUXTYPE}"/contexts/files/file_contexts /run/initramfs > /dev/null
    fi
fi

exit 0
