#!/bin/bash

# called by dracut
check() {
    return 255
}

# called by dracut
depends() {
    is_qemu_virtualized && echo -n "qemu-net "

    for module in network-wicked network-manager network-legacy ; do
        if dracut_module_included "$module" ; then
                network_handler="$module"
                break
            fi
        done;

        if [ -z "$network_handler" ]; then
            if require_binaries wicked; then
                network_handler="network-wicked"
            elif [ -x "$dracutsysrootdir/usr/libexec/nm-initrd-generator" ]; then
                network_handler="network-manager"
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
    local _arch _i _dir

    inst_script "$moddir/netroot.sh" "/sbin/netroot"
    inst_simple "$moddir/net-lib.sh" "/lib/net-lib.sh"
    inst_hook pre-udev 50 "$moddir/ifname-genrules.sh"
    inst_hook cmdline 91 "$moddir/dhcp-root.sh"

    dracut_need_initqueue
}
