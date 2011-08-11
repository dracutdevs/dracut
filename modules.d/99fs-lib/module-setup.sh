#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    return 0
}

depends() {
    return 0
}

install() {
    dracut_install -o umount mount xfs_db xfs_check xfs_repair
    dracut_install -o e2fsck
    dracut_install -o jfs_fsck
    dracut_install -o reiserfsck
    dracut_install -o btrfsck
    dracut_install -o /sbin/fsck*

    inst "$moddir/fs-lib.sh" "/lib/fs-lib.sh"
    touch ${initdir}/etc/fstab.fslib
}
