#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
#
# We don't need to check for ip= errors here, that is handled by the
# cmdline parser script
#
# without $2 means this is for real netroot case
# or it is for manually bring up network ie. for kdump scp vmcore
PATH=/usr/sbin:/usr/bin:/sbin:/bin

type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh
type ip_to_var >/dev/null 2>&1 || . /lib/net-lib.sh

# Huh? No $1?
[ -z "$1" ] && exit 1

# $netif reads easier than $1
netif=$1

# enslave this interface to bond?
if [ -e /tmp/bond.info ]; then
    . /tmp/bond.info
    for slave in $bondslaves ; do
        if [ "$netif" = "$slave" ] ; then
            netif=$bondname
        fi
    done
fi

# bridge this interface?
if [ -e /tmp/bridge.info ]; then
    . /tmp/bridge.info
    for ethname in $ethnames ; do
        if [ "$netif" = "$ethname" ]; then
            if [ "$netif" = "$bondname" ] && [ -n "$DO_BOND_SETUP" ] ; then
                : # We need to really setup bond (recursive call)
            else
                netif="$bridgename"
            fi
        fi
    done
fi

if [ -e /tmp/vlan.info ]; then
    . /tmp/vlan.info
    if [ "$netif" = "$phydevice" ]; then
        if [ "$netif" = "$bondname" ] && [ -n "$DO_BOND_SETUP" ] ; then
            : # We need to really setup bond (recursive call)
        else
            netif="$vlanname"
        fi
    fi
fi

# disable manual ifup while netroot is set for simplifying our logic
# in netroot case we prefer netroot to bringup $netif automaticlly
[ -n "$2" -a "$2" = "-m" ] && [ -z "$netroot" ] && manualup="$2"
[ -z "$netroot" ] && [ -z "$manualup" ] && exit 0
[ -n "$manualup" ] && >/tmp/net.$netif.manualup

# Run dhclient
do_dhcp() {
    # dhclient-script will mark the netif up and generate the online
    # event for nfsroot
    # XXX add -V vendor class and option parsing per kernel
    echo "Starting dhcp for interface $netif"
    dhclient "$@" -1 -q -cf /etc/dhclient.conf -pf /tmp/dhclient.$netif.pid -lf /tmp/dhclient.$netif.lease $netif \
        || echo "dhcp failed"
}

load_ipv6() {
    modprobe ipv6
    i=0
    while [ ! -d /proc/sys/net/ipv6 ]; do
        i=$(($i+1))
        [ $i -gt 10 ] && break
        sleep 0.1
    done
}

do_ipv6auto() {
    load_ipv6
    echo 0 > /proc/sys/net/ipv6/conf/$netif/forwarding
    echo 1 > /proc/sys/net/ipv6/conf/$netif/accept_ra
    echo 1 > /proc/sys/net/ipv6/conf/$netif/accept_redirects
    ip link set $netif up
    wait_for_if_up $netif

    [ -n "$hostname" ] && echo "echo $hostname > /proc/sys/kernel/hostname" > /tmp/net.$netif.hostname

    return 0
}

# Handle static ip configuration
do_static() {
    strstr $ip '*:*:*' && load_ipv6

    ip link set dev $netif up
    wait_for_if_up $netif
    [ -n "$macaddr" ] && ip link set address $macaddr dev $netif
    [ -n "$mtu" ] && ip link set mtu $mtu dev $netif
    if strstr $ip '*:*:*'; then
        # note no ip addr flush for ipv6
        ip addr add $ip/$mask dev $netif
    else
        ip addr flush dev $netif
        ip addr add $ip/$mask brd + dev $netif
    fi

    [ -n "$gw" ] && echo ip route add default via $gw dev $netif > /tmp/net.$netif.gw
    [ -n "$hostname" ] && echo "echo $hostname > /proc/sys/kernel/hostname" > /tmp/net.$netif.hostname

    return 0
}

# loopback is always handled the same way
if [ "$netif" = "lo" ] ; then
    ip link set lo up
    ip addr add 127.0.0.1/8 dev lo
    exit 0
fi

# start bond if needed
if [ -e /tmp/bond.info ]; then
    . /tmp/bond.info

    if [ "$netif" = "$bondname" ] && [ ! -e /tmp/net.$bondname.up ] ; then # We are master bond device
        modprobe bonding
        ip link set $netif down

        # Stolen from ifup-eth
        # add the bits to setup driver parameters here
        for arg in $bondoptions ; do
            key=${arg%%=*};
            value=${arg##*=};
            # %{value:0:1} is replaced with non-bash specific construct
            if [ "${key}" = "arp_ip_target" -a "${#value}" != "0" -a "+${value%%+*}" != "+" ]; then
                OLDIFS=$IFS;
                IFS=',';
                for arp_ip in $value; do
                    echo +$arp_ip > /sys/class/net/${netif}/bonding/$key
                done
                IFS=$OLDIFS;
            else
                echo $value > /sys/class/net/${netif}/bonding/$key
            fi
        done

        ip link set $netif up

        for slave in $bondslaves ; do
            ip link set $slave down
            echo "+$slave" > /sys/class/net/$bondname/bonding/slaves
            ip link set $slave up
            wait_for_if_up $slave
        done

        # add the bits to setup the needed post enslavement parameters
        for arg in $BONDING_OPTS ; do
            key=${arg%%=*};
            value=${arg##*=};
            if [ "${key}" = "primary" ]; then
                echo $value > /sys/class/net/${netif}/bonding/$key
            fi
        done
    fi
fi


# XXX need error handling like dhclient-script

if [ -e /tmp/bridge.info ]; then
    . /tmp/bridge.info
# start bridge if necessary
    if [ "$netif" = "$bridgename" ] && [ ! -e /tmp/net.$bridgename.up ]; then
        brctl addbr $bridgename
        brctl setfd $bridgename 0
        for ethname in $ethnames ; do
            if [ "$ethname" = "$bondname" ] ; then
                DO_BOND_SETUP=yes ifup $bondname -m
            else
                ip link set $ethname up
            fi
            wait_for_if_up $ethname
            brctl addif $bridgename $ethname
        done
    fi
fi

get_vid() {
    case "$1" in
    vlan*)
        return ${1#vlan}
        ;;
    *.*)
        return ${1##*.}
        ;;
    esac
}

if [ "$netif" = "$vlanname" ] && [ ! -e /tmp/net.$vlanname.up ]; then
    modprobe 8021q
    if [ "$phydevice" = "$bondname" ] ; then
        DO_BOND_SETUP=yes ifup $phydevice -m
    else
        ip link set "$phydevice" up
    fi
    wait_for_if_up "$phydevice"
    ip link add dev "$vlanname" link "$phydevice" type vlan id "$(get_vid $vlanname; echo $?)"
fi

# setup nameserver
namesrv=$(getargs nameserver)
if  [ -n "$namesrv" ] ; then
    for s in $namesrv; do
        echo nameserver $s
    done
fi >> /tmp/net.$netif.resolv.conf

# No ip lines default to dhcp
ip=$(getarg ip)

if [ -z "$ip" ]; then
    if [ "$netroot" = "dhcp6" ]; then
        do_dhcp -6
    else
        do_dhcp -4
    fi
fi

# Specific configuration, spin through the kernel command line
# looking for ip= lines
for p in $(getargs ip=); do
    ip_to_var $p
    # skip ibft
    [ "$autoconf" = "ibft" ] && continue

    # If this option isn't directed at our interface, skip it
    [ -n "$dev" ] && [ "$dev" != "$netif" ] && continue

    # Store config for later use
    for i in ip srv gw mask hostname macaddr; do
        eval '[ "$'$i'" ] && echo '$i'="$'$i'"'
    done > /tmp/net.$netif.override

    case $autoconf in
        dhcp|on|any)
            do_dhcp -4 ;;
        dhcp6)
            do_dhcp -6 ;;
        auto6)
            do_ipv6auto ;;
        *)
            do_static ;;
    esac

    case $autoconf in
        dhcp|on|any|dhcp6)
            ;;
        *)
            if [ $? -eq 0 ]; then
                setup_net $netif
                source_hook initqueue/online $netif
                if [ -z "$manualup" ]; then
                    /sbin/netroot $netif
                fi
            fi
            ;;
    esac

    break
done
exit 0
