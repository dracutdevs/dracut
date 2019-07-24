#!/bin/bash

# called by dracut
check() {
    return 255
}

# called by dracut
depends() {
    echo -n "kernel-network-modules "
    # RHEL 8.1: Default to network-legacy unless the user chose
    # network-manager manually
    if ! dracut_module_included "network-manager" ; then
        echo "network-legacy"
    fi
    return 0
}

# called by dracut
installkernel() {
    return 0
}

# called by dracut
install() {
    local _arch _i _dir

    inst_script "$moddir/netroot.sh" "/sbin/netroot"
    inst_simple "$moddir/net-lib.sh" "/lib/net-lib.sh"
    inst_hook pre-udev 50 "$moddir/ifname-genrules.sh"
    inst_hook cmdline 91 "$moddir/dhcp-root.sh"

    dracut_need_initqueue
}
