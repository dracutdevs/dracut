#!/bin/bash

# called by dracut
check() {
    local _rootdev

    # if an rbd device is not somewhere in the chain of devices root is
    # mounted on, fail the hostonly check.
    [[ $hostonly ]] || [[ $mount_needs ]] && {

        is_rbd() {
            local _dev=$1 d=

            [[ -L "/sys/dev/block/$_dev" ]] || return
            d="$(readlink -ev /sys/dev/block/$_dev)"
            [[ ${d##*/} =~ "rbd" ]] || return 1
        }

        _rootdev=$(find_root_block_device)
        [[ -b /dev/block/$_rootdev ]] || return 1
        check_block_and_slaves is_rbd "$_rootdev" || return 255
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
    instmods rbd aes cbc
}

# called by dracut
install() {
    inst_multiple grep tail
    # check rbd options in cmdline
    inst_hook cmdline 90 "$moddir/parse-rbdroot.sh"
    # handler for netroot.sh
    inst "$moddir/rbdroot.sh" "/sbin/rbdroot"
    # shell library
    inst "$moddir/rbd-lib.sh" "/lib/rbd-lib.sh"
    dracut_need_initqueue
}

