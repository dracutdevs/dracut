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
    echo "net-lib kernel-network-modules $network_handler"
    return 0
}
