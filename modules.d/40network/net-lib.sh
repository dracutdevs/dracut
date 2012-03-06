#!/bin/sh

get_ip() {
    local iface="$1" ip=""
    ip=$(ip -o -f inet addr show $iface)
    ip=${ip%%/*}
    ip=${ip##* }
}

iface_for_remote_addr() {
    set -- $(ip -o route get to $1)
    echo $5
}

iface_for_mac() {
    local interface="" mac="$(echo $1 | tr '[:upper:]' '[:lower:]')"
    for interface in /sys/class/net/*; do
        if [ $(cat $interface/address) = "$mac" ]; then
            echo ${interface##*/}
        fi
    done
}

iface_has_link() {
    local interface="$1" flags=""
    [ -n "$interface" ] || return 2
    interface="/sys/class/net/$interface"
    [ -d "$interface" ] || return 2
    flags=$(cat $interface/flags)
    echo $(($flags|0x41)) > $interface/flags # 0x41: IFF_UP|IFF_RUNNING
    [ "$(cat $interface/carrier)" = 1 ] || return 1
    # XXX Do we need to reset the flags here? anaconda never bothered..
}

all_ifaces_up() {
    local iface="" IFACES=""
    [ -e "/tmp/net.ifaces" ] && read IFACES < /tmp/net.ifaces
    for iface in $IFACES; do
        [ -e /tmp/net.$iface.up ] || return 1
    done
}

get_netroot_ip() {
    local prefix="" server="" rest=""
    splitsep "$1" ":" prefix server rest
    case $server in
        [0-9]*\.[0-9]*\.[0-9]*\.[0-9]*) echo "$server"; return 0 ;;
    esac
    return 1
}

ip_is_local() {
    strstr "$(ip route get $1 2>/dev/null)" " via "
}

ifdown() {
    local netif="$1"
    # ip down/flush ensures that routing info goes away as well
    ip link set $netif down
    ip addr flush dev $netif
    echo "#empty" > /etc/resolv.conf
    # TODO: send "offline" uevent?
}

setup_net() {
    local netif="$1" f="" gw_ip="" netroot_ip="" iface="" IFACES=""
    [ -e /tmp/net.$netif.up ] || return 1
    [ -e "/tmp/net.ifaces" ] && read IFACES < /tmp/net.ifaces
    [ -z "$IFACES" ] && IFACES="$netif"
    for iface in $IFACES ; do
        . /tmp/net.$iface.up
    done
    # run the scripts written by ifup
    [ -e /tmp/net.$netif.gw ]            && . /tmp/net.$netif.gw
    [ -e /tmp/net.$netif.hostname ]      && . /tmp/net.$netif.hostname
    [ -e /tmp/net.$netif.override ]      && . /tmp/net.$netif.override
    [ -e /tmp/dhclient.$netif.dhcpopts ] && . /tmp/dhclient.$netif.dhcpopts
    # set up resolv.conf
    [ -e /tmp/net.$netif.resolv.conf ] && \
        cp -f /tmp/net.$netif.resolv.conf /etc/resolv.conf

    # Handle STP Timeout: arping the default gateway.
    # (or the root server, if a) it's local or b) there's no gateway.)
    # Note: This assumes that if no router is present the
    # root server is on the same subnet.

    # Get DHCP-provided router IP, or the cmdline-provided "gw=" argument
    [ -n "$new_routers" ] && gw_ip=${new_routers%%,*}
    [ -n "$gw" ] && gw_ip=$gw

    # Get the "netroot" IP (if there's an IP address in there)
    netroot_ip=$(get_netroot_ip $netroot)

    # try netroot if it's local (or there's no gateway)
    if ip_is_local $netroot_ip || [ -z "$gw_ip" ]; then
        dest="$netroot_ip"
    else
        dest="$gw_ip"
    fi
    if [ -n "$dest" ] && ! arping -q -f -w 60 -I $netif $dest ; then
        info "Resolving $dest via ARP on $netif failed"
    fi
}

set_ifname() {
    local name="$1" mac="$2" num=0 n=""
    # if it's already set, return the existing name
    for n in $(getargs ifname=); do
        strstr "$n" "$mac" && echo ${n%%:*} && return
    done
    # otherwise, pick a new name and use that
    while [ -e /sys/class/$name$num ]; do num=$(($num+1)); done
    echo "ifname=$name$num:$mac" >> /etc/cmdline.d/45-ifname.conf
    echo "$name$num"
}

ibft_to_cmdline() {
    local iface="" mac="" dev=""
    local dhcp="" ip="" gw="" mask="" hostname=""
    modprobe -q iscsi_ibft
    (
        for iface in /sys/firmware/ibft/ethernet*; do
            [ -e ${iface}/mac ] || continue
            mac=$(read a < ${iface}/mac; echo $a)
            [ -z "$ifname_mac" ] && continue
            dev=$(set_ifname ibft $ifname_mac)
            dhcp=$(read a < ${iface}/dhcp; echo $a)
            if [ -n "$dhcp" ]; then
                echo "ip=$dev:dhcp"
            else
                ip=$(read a < ${iface}/ip-addr; echo $a)
                gw=$(read a < ${iface}/gateway; echo $a)
                mask=$(read a < ${iface}/subnet-mask; echo $a)
                hostname=$(read a < ${iface}/hostname; echo $a)
                echo "ip=$ip::$gw:$mask:$hostname:$dev:none"
            fi
        done
    ) >> /etc/cmdline.d/40-ibft.conf
    # reread cmdline
    unset CMDLINE
}
