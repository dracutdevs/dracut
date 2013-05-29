#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    return 0
}

depends() {
    return 0
}


echo_fs_helper() {
    local dev=$1 fs=$2
    case "$fs" in
        xfs)
            echo -n " xfs_db xfs_repair xfs_check "
            ;;
        ext?)
            echo -n " e2fsck "
            ;;
        jfs)
            echo -n " jfs_fsck "
            ;;
        reiserfs)
            echo -n " reiserfsck "
            ;;
        btrfs)
            echo -n " btrfsck "
            ;;
        *)
            [[ -x fsck.$fs ]] && echo -n " fsck.$fs "
            ;;
    esac
}

include_fs_helper_modules() {
    local dev=$1 fs=$2
    case "$fs" in
        xfs|btrfs)
            instmods crc32c
            ;;
    esac
}

installkernel() {
    # xfs and btrfs needs crc32c...
    if [[ $hostonly ]]; then
        for_each_host_dev_fs include_fs_helper_modules
        :
    else
        instmods crc32c
    fi
}

install() {
    local _helpers

    inst "$moddir/fs-lib.sh" "/lib/fs-lib.sh"
    > ${initdir}/etc/fstab.empty

    inst_hook pre-mount 99 "$moddir/mount-early.sh"
    inst_hook pre-pivot 99 "$moddir/mount-late.sh"

    [[ "$nofscks" = "yes" ]] && return

    if [[ "$fscks" = "${fscks#*[^ ]*}" ]]; then
        _helpers="\
            umount mount /sbin/fsck*
            xfs_db xfs_check xfs_repair
            e2fsck jfs_fsck reiserfsck btrfsck
        "
        if [[ $hostonly ]]; then
            _helpers="umount mount "
            _helpers+=$(for_each_host_dev_fs echo_fs_helper)
        fi
    else
        _helpers="$fscks"
    fi

    if strstr "$_helpers" e2fsck && [ -e /etc/e2fsck.conf ]; then
        inst_simple /etc/e2fsck.conf
    fi

    dracut_install -o $_helpers
}
