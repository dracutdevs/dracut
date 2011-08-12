#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    local _program
    . $dracutfunctions

    for _program in ip arping dhclient ; do
        if ! type -P $_program >/dev/null; then
            derror "Could not find program \"$_program\" required by network."
            return 1
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
        local _net_drivers='eth_type_trans|register_virtio_device'
        local _unwanted_drivers='/(wireless|isdn|uwb)/'
        egrep -q $_net_drivers "$1" && \
            egrep -qv 'iw_handler_get_spy' "$1" && \
            [[ ! $1 =~ $_unwanted_drivers ]]
    }

    instmods $(filter_kernel_modules_by_path drivers/net net_module_test)

    instmods ecb arc4
    # bridge modules
    instmods bridge stp llc
    instmods ipv6
    # bonding
    instmods bonding
}

install() {
    local _arch _i _dir
    dracut_install ip arping tr dhclient
    dracut_install -o brctl ifenslave
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

    _arch=$(uname -m)

    for _dir in "$usrlibdir/tls/$_arch" "$usrlibdir/tls" "$usrlibdir/$_arch" \
        "$usrlibdir" "$libdir"; do
        for _i in "$_dir"/libnss_dns.so.* "$_dir"/libnss_mdns4_minimal.so.*; do
            [ -e "$_i" ] && dracut_install "$_i"
        done
    done

}

