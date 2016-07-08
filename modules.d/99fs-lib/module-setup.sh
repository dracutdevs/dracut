#!/bin/bash

# called by dracut
check() {
    return 0
}

# called by dracut
depends() {
    return 0
}


echo_fs_helper() {
    local dev=$1 fs=$2
    case "$fs" in
        xfs)
            echo -n " xfs_db xfs_repair xfs_check xfs_metadump"
            ;;
        ext?)
            echo -n " e2fsck "
            ;;
        f2fs)
            echo -n " fsck.f2fs "
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
    esac

    echo -n " fsck.$fs "
    return 0
}

include_fs_helper_modules() {
    local dev=$1 fs=$2
    case "$fs" in
        xfs|btrfs)
            instmods crc32c
            ;;
        f2fs)
            instmods crc32
            ;;
    esac
}

# called by dracut
installkernel() {
    # xfs and btrfs needs crc32c...
    if [[ $hostonly ]]; then
        for_each_host_dev_fs include_fs_helper_modules
        :
    else
        instmods crc32c
    fi
}

# called by dracut
install() {
    local _helpers

    inst "$moddir/fs-lib.sh" "/lib/fs-lib.sh"
    > ${initdir}/etc/fstab.empty

    [[ "$nofscks" = "yes" ]] && return

    if [[ "$fscks" = "${fscks#*[^ ]*}" ]]; then
        _helpers="\
            umount mount /sbin/fsck*
            xfs_db xfs_check xfs_repair xfs_metadump
            e2fsck fsck.f2fs jfs_fsck reiserfsck btrfsck
        "
        if [[ $hostonly ]]; then
            _helpers="umount mount "
            _helpers+=$(for_each_host_dev_fs echo_fs_helper)
        fi
    else
        _helpers="$fscks"
    fi

    if [[ "$_helpers" ==  *e2fsck* ]] && [ -e /etc/e2fsck.conf ]; then
        inst_simple /etc/e2fsck.conf
    fi

    inst_multiple -o $_helpers fsck
}
