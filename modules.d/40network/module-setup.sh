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

    net_module_filter() {
        local _net_drivers='eth_type_trans|register_virtio_device'
        local _unwanted_drivers='/(wireless|isdn|uwb)/'
        # subfunctions inherit following FDs
        local _merge=8 _side2=9
        function nmf1() {
            local _fname _fcont
            while read _fname; do
                [[ $_fname =~ $_unwanted_drivers ]] && continue
                case "$_fname" in
                    *.ko)    _fcont="$(<        $_fname)" ;;
                    *.ko.gz) _fcont="$(gzip -dc $_fname)" ;;
                    *.ko.xz) _fcont="$(xz -dc   $_fname)" ;;
                esac
                [[   $_fcont =~ $_net_drivers
                && ! $_fcont =~ iw_handler_get_spy ]] \
                && echo "$_fname"
            done
        }
        function rotor() {
            local _f1 _f2
            while read _f1; do
                echo "$_f1"
                if read _f2; then
                    echo "$_f2" 1>&${_side2}
                fi
            done | nmf1 1>&${_merge}
        }
        # Use two parallel streams to filter alternating modules.
        set +x
        eval "( ( rotor ) ${_side2}>&1 | nmf1 ) ${_merge}>&1"
        [[ $debug ]] && set -x
    }

    { find_kernel_modules_by_path drivers/net; find_kernel_modules_by_path drivers/s390/net; } \
        | net_module_filter | instmods

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
    inst "$moddir/ifup.sh" "/sbin/ifup"
    inst "$moddir/netroot.sh" "/sbin/netroot"
    inst "$moddir/dhclient-script.sh" "/sbin/dhclient-script"
    inst "$moddir/net-lib.sh" "/lib/net-lib.sh"
    inst_simple "$moddir/dhclient.conf" "/etc/dhclient.conf"
    inst_hook pre-udev 50 "$moddir/ifname-genrules.sh"
    inst_hook pre-udev 60 "$moddir/net-genrules.sh"
    inst_hook cmdline 91 "$moddir/dhcp-root.sh"
    inst_hook cmdline 96 "$moddir/parse-bond.sh"
    inst_hook cmdline 97 "$moddir/parse-bridge.sh"
    inst_hook cmdline 98 "$moddir/parse-ip-opts.sh"
    inst_hook cmdline 99 "$moddir/parse-ifname.sh"
    inst_hook pre-pivot 10 "$moddir/kill-dhclient.sh"

    _arch=$(uname -m)

    inst_libdir_file {"tls/$_arch/",tls/,"$_arch/",}"libnss_dns.so.*"
    inst_libdir_file {"tls/$_arch/",tls/,"$_arch/",}"libnss_mdns4_minimal.so.*"
}

