#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

# called by dracut
check() {
    local _rootdev
    # If our prerequisites are not met, fail.
    require_binaries nbd-client || return 1

    # if an nbd device is not somewhere in the chain of devices root is
    # mounted on, fail the hostonly check.
    [[ $hostonly ]] || [[ $mount_needs ]] && {
        is_nbd() { [[ -b /dev/block/$1 && $1 == 43:* ]] ;}

        _rootdev=$(find_root_block_device)
        [[ -b /dev/block/$_rootdev ]] || return 1
        check_block_and_slaves is_nbd "$_rootdev" || return 255
    }

    return 0
}

# called by dracut
depends() {
    # We depend on network modules being loaded
    echo network rootfs-block
}

# called by dracut
installkernel() {
    instmods nbd
}

# called by dracut
install() {
    inst nbd-client
    inst_hook cmdline 90 "$moddir/parse-nbdroot.sh"
    inst_script "$moddir/nbdroot.sh" "/sbin/nbdroot"
    dracut_need_initqueue
}

