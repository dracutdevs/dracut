#!/bin/bash

check() {
    require_binaries ntfs-3g || return 1
    return 255
}

depends() {
    echo dmsquash-live
    return 0
}

install() {
    inst_multiple fusermount mount.fuse ntfs-3g
    inst_script "$moddir/mount-ntfs-3g.sh" "/sbin/mount-ntfs-3g"
    dracut_need_initqueue
}

installkernel() {
    hostonly='' instmods fuse
}
