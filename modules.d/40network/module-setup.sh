#!/bin/bash

# called by dracut
check() {
    return 255
}

# called by dracut
depends() {
    is_qemu_virtualized && echo -n "qemu-net "

    preferred_network_handler="${preferred_network_handler:-none}"
    case "$preferred_network_handler" in
		none )
			for module in network-wicked network-manager network-legacy systemd-networkd; do
				if dracut_module_included "$module"; then
					network_handler="$module"
					break
				fi
			done
		;;
		network-wicked | network-manager | network-legacy | systemd-networkd )
			network_handler="$preferred_network_handler"
		;;
		* )
			dwarn "Preferred network module $preferred_network_handler is not known, ignoring."
		;;
    esac

    if [ -z "$network_handler" ]; then
        if [[ -x $dracutsysrootdir$systemdsystemunitdir/wicked.service ]]; then
            network_handler="network-wicked"
        elif [[ -x $dracutsysrootdir/usr/libexec/nm-initrd-generator ]]; then
            network_handler="network-manager"
        elif [[ -x $dracutsysrootdir$systemdutildir/systemd-networkd ]]; then
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

    dracut_need_initqueue
}
