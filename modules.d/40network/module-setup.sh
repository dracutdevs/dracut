#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    . $dracutfunctions

    for program in ip arping; do 
        if ! type -P $program >/dev/null; then
            dwarning "Could not find program \"$program\" required by network." 
            return 1
        fi
    done
    for program in dhclient brctl ifenslave tr; do
        if ! type -P $program >/dev/null; then
            dwarning "Could not find program \"$program\" it might be required by network." 
        fi
    done

    return 255
}

depends() {
    [ -d /etc/sysconfig/network-scripts/ ] && echo ifcfg
    return 0
}

installkernel() {
    # Include wired net drivers, excluding wireless

    net_module_test() {
        local net_drivers='eth_type_trans|register_virtio_device'
        local unwanted_drivers='/(wireless|isdn|uwb)/'
        egrep -q $net_drivers "$1" && \
            egrep -qv 'iw_handler_get_spy' "$1" && \
            [[ ! $1 =~ $unwanted_drivers ]]
    }

    instmods $(filter_kernel_modules net_module_test)

    instmods ecb arc4
    # bridge modules
    instmods bridge stp llc
    instmods ipv6
    # bonding
    instmods bonding
}

install() {
    dracut_install ip dhclient brctl arping ifenslave tr
    inst "$moddir/ifup" "/sbin/ifup"
    inst "$moddir/netroot" "/sbin/netroot"
    inst "$moddir/dhclient-script" "/sbin/dhclient-script"
    inst "$moddir/dhclient.conf" "/etc/dhclient.conf" 
    inst_hook pre-udev 50 "$moddir/ifname-genrules.sh"
    inst_hook pre-udev 60 "$moddir/net-genrules.sh"
    inst_hook cmdline 91 "$moddir/dhcp-root.sh"
    inst_hook cmdline 96 "$moddir/parse-bond.sh"
    inst_hook cmdline 97 "$moddir/parse-bridge.sh"
    inst_hook cmdline 98 "$moddir/parse-ip-opts.sh"
    inst_hook cmdline 99 "$moddir/parse-ifname.sh"
    inst_hook pre-pivot 10 "$moddir/kill-dhclient.sh"

    arch=$(uname -m)

    for dir in "$usrlibdir/tls/$arch" "$usrlibdir/tls" "$usrlibdir/$arch" \
        "$usrlibdir" "$libdir"; do
        for i in "$dir"/libnss_dns.so.* "$dir"/libnss_mdns4_minimal.so.*; do
            [ -e "$i" ] && dracut_install "$i"
        done
    done

}

