#!/bin/bash

# called by dracut
check() {
    [[ $hostonly ]] || [[ $mount_needs ]] && {
        [ -d /sys/firmware/efi ] || return 255
    }
    require_binaries dcbtool fipvlan lldpad ip readlink || return 1
    return 0
}

# called by dracut
depends() {
    echo fcoe uefi-lib
    return 0
}

# called by dracut
install() {
    inst_hook cmdline 20 "$moddir/parse-uefifcoe.sh"
}
