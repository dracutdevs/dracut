#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
#
# We get called like this:
# fcoe-up <network-device> <dcb|nodcb>
#
# Note currently only nodcb is supported, the dcb option is reserved for
# future use.

PATH=/usr/sbin:/usr/bin:/sbin:/bin

# Huh? Missing arguments ??
[ -z "$1" -o -z "$2" ] && exit 1

type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh
type ip_to_var >/dev/null 2>&1 || . /lib/net-lib.sh

netif=$1
dcb=$2
vlan="yes"

iflink=$(cat /sys/class/net/$netif/iflink)
ifindex=$(cat /sys/class/net/$netif/ifindex)
if [ "$iflink" != "$ifindex" ] ; then
    # Skip VLAN devices
    exit 0
fi

ip link set dev $netif up
linkup "$netif"

netdriver=$(readlink -f /sys/class/net/$netif/device/driver)
netdriver=${netdriver##*/}

write_fcoemon_cfg() {
    echo FCOE_ENABLE=\"yes\" > /etc/fcoe/cfg-$netif
    if [ "$dcb" = "dcb" ]; then
        echo DCB_REQUIRED=\"yes\" >> /etc/fcoe/cfg-$netif
    else
        echo DCB_REQUIRED=\"no\" >> /etc/fcoe/cfg-$netif
    fi
    if [ "$vlan" = "yes" ]; then
	    echo AUTO_VLAN=\"yes\" >> /etc/fcoe/cfg-$netif
    else
	    echo AUTO_VLAN=\"no\" >> /etc/fcoe/cfg-$netif
    fi
    echo MODE=\"fabric\" >> /etc/fcoe/cfg-$netif
}

if [ "$dcb" = "dcb" ]; then
    # wait for lldpad to be ready
    i=0
    while [ $i -lt 60 ]; do
        lldptool -p && break
        info "Waiting for lldpad to be ready"
        sleep 1
        i=$(($i+1))
    done

    while [ $i -lt 60 ]; do
        dcbtool sc "$netif" dcb on && break
        info "Retrying to turn dcb on"
        sleep 1
        i=$(($i+1))
    done

    while [ $i -lt 60 ]; do
        dcbtool sc "$netif" pfc e:1 a:1 w:1 && break
        info "Retrying to turn dcb on"
        sleep 1
        i=$(($i+1))
    done

    while [ $i -lt 60 ]; do
        dcbtool sc "$netif" app:fcoe e:1 a:1 w:1 && break
        info "Retrying to turn fcoe on"
        sleep 1
        i=$(($i+1))
    done

    sleep 1

    write_fcoemon_cfg
    fcoemon --syslog
elif [ "$netdriver" = "bnx2x" ]; then
    # If driver is bnx2x, do not use /sys/module/fcoe/parameters/create but fipvlan
    modprobe 8021q
    udevadm settle --timeout=30
    # Sleep for 3 s to allow dcb negotiation
    sleep 3
    fipvlan "$netif" -c -s
else
    vlan="no"
    write_fcoemon_cfg
    fcoemon --syslog
fi

need_shutdown
