#!/bin/bash

set -e

# do some sanity checks first
[ -e /run/initramfs/bin/sh ] && exit 0
[ -e /run/initramfs/.need_shutdown ] || exit 0

# SIGTERM signal is received upon forced shutdown: ignore the signal
# We want to remain alive to be able to trap unpacking errors to avoid
# switching root to an incompletely unpacked initramfs
trap 'echo "Received SIGTERM signal, ignoring!" >&2' TERM

[[ $dracutbasedir ]] || dracutbasedir=/usr/lib/dracut

# shellcheck source=./dracut-functions.sh
. "$dracutbasedir"/dracut-functions.sh

mount -o ro /boot &> /dev/null || true

# shellcheck disable=SC2119
IMG="$(get_default_initramfs_image)"
if [[ -z $IMG ]]; then
    echo "No initramfs image found to restore!" >&2
    exit 1
fi

# check if initramfs image contains early microcode and skip it
read -r -N 6 bin < "$IMG"
case $bin in
    $'\x71\xc7'* | 070701)
        CAT="cat --"
        if has_early_microcode "$IMG"; then
            SKIP="$dracutbasedir/skipcpio"
            if ! [[ -x $SKIP ]]; then
                echo "'$SKIP' not found, cannot skip early microcode to extract $IMG" >&2
                exit 1
            fi
        fi
        ;;
esac

if [[ $SKIP ]]; then
    bin="$($SKIP "$IMG" | { read -r -N 6 bin && echo "$bin"; })"
else
    read -r -N 6 bin < "$IMG"
fi

# check if initramfs image is compressed
CAT=$(get_decompression_command "$bin")

type "${CAT%% *}" > /dev/null 2>&1 || {
    echo "'${CAT%% *}' not found, cannot unpack $IMG" >&2
    exit 1
}

skipcpio() {
    $SKIP "$@" | $ORIG_CAT
}

if [[ $SKIP ]]; then
    ORIG_CAT="$CAT"
    CAT=skipcpio
fi

# decompress and extract initramfs image
cd /run/initramfs
if ($CAT "$IMG" | cpio -id --no-absolute-filenames --quiet > /dev/null); then
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
