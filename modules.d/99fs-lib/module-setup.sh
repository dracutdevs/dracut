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
    local _helpers

    inst "$moddir/fs-lib.sh" "/lib/fs-lib.sh"
    touch ${initdir}/etc/fstab.empty

    [[ "$nofscks" = "yes" ]] && return

    if [[ "$fscks" = "${fscks#*[^ ]*}" ]]; then
        _helpers="\
            umount mount /sbin/fsck*
            xfs_db xfs_check xfs_repair
            e2fsck jfs_fsck reiserfsck btrfsck
        "
    else
        _helpers="$fscks"
    fi

    dracut_install -o $_helpers
}
