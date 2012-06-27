#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    local _rootdev
    # if we don't have btrfs installed on the host system,
    # no point in trying to support it in the initramfs.
    type -P btrfs >/dev/null || return 1

    [[ $hostonly ]] || [[ $mount_needs ]] && {
        local _found
        for fs in ${host_fs_types[@]}; do
            strstr "$fs" "\|btrfs" && _found="1"
        done
        [[ $_found ]] || return 1
        unset _found
    }

    return 0
}

depends() {
    echo udev-rules
    return 0
}

installkernel() {
    instmods btrfs crc32c
}

install() {
    inst_rules "$moddir/80-btrfs.rules"
    inst_script "$moddir/btrfs_finished.sh" /sbin/btrfs_finished
    inst_script "$moddir/btrfs_timeout.sh" /sbin/btrfs_timeout
    dracut_install btrfs btrfsck
}

