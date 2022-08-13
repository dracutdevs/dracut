#!/bin/sh

# called by dracut
check() {
    return 0
}

# called by dracut
depends() {
    return 0
}

echo_fs_helper() {
    local fs=$2
    case "$fs" in
        xfs) echo xfs_db xfs_repair xfs_check xfs_metadump ;;
        ext?) echo e2fsck ;;
        jfs) echo jfs_fsck ;;
        reiserfs) echo reiserfsck ;;
        btrfs) echo btrfsck ;;
    esac
    echo "fsck.$fs"
}

include_fs_helper_modules() {
    local fs=$2
    case "$fs" in
        xfs | btrfs | ext4 | ext3)
            instmods crc32c
            ;;
        f2fs)
            instmods crc32
            ;;
    esac
}

# called by dracut
installkernel() {
    # xfs/btrfs/ext4 need crc32c, f2fs needs crc32
    if [ -n "$hostonly" ]; then
        for_each_host_dev_fs include_fs_helper_modules || :
    else
        instmods crc32c crc32
    fi
}

# called by dracut
install() {
    local _fscks

    inst "$moddir/fs-lib.sh" "/lib/fs-lib.sh"
    : > "${initdir}"/etc/fstab.empty

    [ "$nofscks" = "yes" ] && return

    _fscks="$fscks"
    if [ "$fscks" = "${fscks#*[^ ]*}" ]; then
        _fscks="xfs_db xfs_check xfs_repair xfs_metadump e2fsck jfs_fsck reiserfsck btrfsck $(echo /sbin/fsck* /usr/sbin/fsck*) $([ -n "$hostonly" ] && for_each_host_dev_fs echo_fs_helper)"
    fi

    [ "${_fscks#*e2fsck}" != "$_fscks" ] && [ -e "$dracutsysrootdir/etc/e2fsck.conf" ] && inst_simple /etc/e2fsck.conf

    # shellcheck disable=SC2086
    inst_multiple -o $_fscks umount mount fsck
}
