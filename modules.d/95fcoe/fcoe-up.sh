#!/bin/sh
#
# We get called like this:
# fcoe-up <network-device> <dcb|nodcb>
#
# Note currently only nodcb is supported, the dcb option is reserved for
# future use.

PATH=/usr/sbin:/usr/bin:/sbin:/bin
type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh
type ip_to_var >/dev/null 2>&1 || . /lib/net-lib.sh

# Huh? Missing arguments ??
[ -z "$1" -o -z "$2" ] && exit 1

netif=$1
dcb=$2

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
        dcbtool sc "$netif" app:fcoe e:1 a:1 w:1 && break
        info "Retrying to turn fcoe on"
        sleep 1
        i=$(($i+1))
    done

    sleep 1

    fipvlan "$netif" -c -s
elif [ "$netdriver" = "bnx2x" ]; then
    # If driver is bnx2x, do not use /sys/module/fcoe/parameters/create but fipvlan
    modprobe 8021q
    udevadm settle --timeout=30
    # Sleep for 3 s to allow dcb negotiation
    sleep 3
    fipvlan "$netif" -c -s
else
    echo -n "$netif" > /sys/module/fcoe/parameters/create
fi

need_shutdown
