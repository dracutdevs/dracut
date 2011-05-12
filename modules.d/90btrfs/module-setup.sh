#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    local _rootdev
    # if we don't have btrfs installed on the host system,
    # no point in trying to support it in the initramfs.
    type -P btrfs >/dev/null || return 1

    . $dracutfunctions
    [[ $debug ]] && set -x

    is_btrfs() { get_fs_type /dev/block/$1 | grep -q btrfs; }

    if [[ $hostonly ]]; then
        _rootdev=$(find_root_block_device)
        if [[ $_rootdev ]]; then
            is_btrfs "$_rootdev" || return 1
        fi
    fi

    return 0
}

depends() {
    echo udev-rules
    return 0
}

installkernel() {
    instmods btrfs
}

install() {
    inst_rules "$moddir/80-btrfs.rules"
    dracut_install btrfs
}

