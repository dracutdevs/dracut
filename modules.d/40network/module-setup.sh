#!/bin/bash

# called by dracut
check() {
    return 255
}

# called by dracut
depends() {
    is_qemu_virtualized && echo -n "qemu-net "

    for module in connman network-manager network-legacy systemd-networkd; do
        if dracut_module_included "$module"; then
            network_handler="$module"
            break
        fi
    done

    if [ -z "$network_handler" ]; then
        if check_module "connman"; then
            network_handler="connman"
        elif check_module "network-manager"; then
            network_handler="network-manager"
        elif check_module "systemd-networkd"; then
            network_handler="systemd-networkd"
        else
            network_handler="network-legacy"
        fi
    fi
    echo "kernel-network-modules $network_handler"
    return 0
}

# called by dracut
installkernel() {
    return 0
}

# called by dracut
install() {
    inst_script "$moddir/netroot.sh" "/sbin/netroot"
    inst_simple "$moddir/net-lib.sh" "/lib/net-lib.sh"
    inst_hook pre-udev 50 "$moddir/ifname-genrules.sh"
    inst_hook cmdline 91 "$moddir/dhcp-root.sh"
    inst_multiple ip sed awk grep pgrep tr
    inst_multiple -o arping arping2
    dracut_need_initqueue
}
