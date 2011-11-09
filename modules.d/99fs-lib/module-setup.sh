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
        if [[ $hostonly ]]; then
            print_fs_type() { get_fs_type /dev/block/$1; }
            _rootdev=$(find_root_block_device)
            if [[ $_rootdev ]]; then
                _helpers="umount mount "
                for fs in $(check_block_and_slaves print_fs_type  "$_rootdev"); do
                    case "$fs" in
                        xfs)
                            _helpers+=" xfs_db xfs_repair xfs_check "
                            ;;
                        ext?)
                            _helpers+=" e2fsck "
                            ;;
                        jfs)
                            _helpers+=" jfs_fsck "
                            ;;
                        reiserfs)
                            _helpers+=" reiserfsck "
                            ;;
                        btrfs)
                            _helpers+=" btrfsck "
                            ;;
                        *)
                            [[ -x fsck.$fs ]] && _helpers+= " fsck.$fs "
                            ;;
                    esac
                done
            fi
        fi
    else
        _helpers="$fscks"
    fi

    if strstr "$_helpers" e2fsck && [ -e /etc/e2fsck.conf ]; then
        inst_simple /etc/e2fsck.conf
    fi

    dracut_install -o $_helpers
}
