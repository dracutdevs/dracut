#!/bin/bash

# called by dracut
check() {
    is_fcoe() {
        block_is_fcoe "$1" || return 1
    }

    [[ $hostonly ]] || [[ $mount_needs ]] && {
        for_each_host_dev_and_slaves is_fcoe || return 255
        [ -d /sys/firmware/efi ] || return 255
    }

    require_binaries dcbtool fipvlan lldpad ip readlink || return 1
    return 0
}

# called by dracut
depends() {
    echo fcoe uefi-lib bash
    return 0
}

# called by dracut
install() {
    inst_hook cmdline 20 "$moddir/parse-uefifcoe.sh"
}
