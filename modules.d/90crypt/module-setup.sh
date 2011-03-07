#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    # if cryptsetup is not installed, then we cannot support encrypted devices.
    type -P cryptsetup >/dev/null || return 1

    . $dracutfunctions

    is_crypt() { [[ $(get_fs_type /dev/block/$1) = crypto_LUKS ]]; }

    [[ $hostonly ]] && {
        rootdev=$(find_root_block_device)
        if [[ $rootdev ]]; then
            # root lives on a block device, so we can be more precise about 
            # hostonly checking
            check_block_and_slaves is_crypt "$rootdev" || return 1
        else
            # root is not on a block device, use the shotgun approach
            blkid | grep -q crypto\?_LUKS || return 1
        fi
    }

    return 0
}

depends() {
    echo dm rootfs-block
    return 0
}

installkernel() {
    instmods dm_crypt =crypto
}

install() {
    inst cryptsetup 
    inst rmdir
    inst readlink
    inst "$moddir"/cryptroot-ask.sh /sbin/cryptroot-ask
    inst "$moddir"/probe-keydev.sh /sbin/probe-keydev
    inst_hook cmdline 10 "$moddir/parse-keydev.sh"
    inst_hook cmdline 30 "$moddir/parse-crypt.sh"
    inst_hook pre-pivot 30 "$moddir/crypt-cleanup.sh"
    inst /etc/crypttab
    inst "$moddir/crypt-lib.sh" "/lib/dracut-crypt-lib.sh"
}

