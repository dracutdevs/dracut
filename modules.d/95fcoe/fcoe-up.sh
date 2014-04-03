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
type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh
type ip_to_var >/dev/null 2>&1 || . /lib/net-lib.sh

# Huh? Missing arguments ??
[ -z "$1" -o -z "$2" ] && exit 1

netif=$1
dcb=$2

linkup "$netif"

netdriver=$(readlink -f /sys/class/net/$netif/device/driver)
netdriver=${netdriver##*/}

if [ "$dcb" = "dcb" ]; then
    # Note lldpad will stay running after switchroot, the system initscripts
    # are to kill it and start a new lldpad to take over. Data is transfered
    # between the 2 using a shm segment
    lldpad -d
    # wait for lldpad to be ready
    i=0
    while [ $i -lt 60 ]; do
        lldptool -p && break
        info "Waiting for lldpad to be ready"
        sleep 1
        i=$(($i+1))
    done

    # on some systems lldpad needs some time
    # sleep until we find a better solution
    sleep 30

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
