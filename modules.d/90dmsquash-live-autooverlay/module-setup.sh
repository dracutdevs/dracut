#!/bin/sh

check() {
    # including a module dedicated to live environments in a host-only initrd doesn't make sense
    [ "$hostonly" ] && return 1
    return 255
}

depends() {
    echo dmsquash-live
    return 0
}

installkernel() {
    instmods btrfs ext4 f2fs xfs
}

install() {
    inst_multiple lsblk cat mkdir mount parted readlink rmdir umount setfattr
    inst_multiple -o mkfs.btrfs mkfs.ext4 mkfs.f2fs mkfs.xfs
    # shellcheck disable=SC2154
    inst_hook pre-udev 25 "$moddir/create-overlay-genrules.sh"
    inst_script "$moddir/create-overlay.sh" "/sbin/create-overlay"
    dracut_need_initqueue
}
