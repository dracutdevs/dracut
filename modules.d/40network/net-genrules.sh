#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

# pxelinux provides macaddr '-' separated, but we need ':'
fix_bootif() {
    local macaddr=${1}
    local IFS='-'
    macaddr=$(for i in ${macaddr} ; do echo -n $i:; done)
    macaddr=${macaddr%:}
    # strip hardware type field from pxelinux
    [ -n "${macaddr%??:??:??:??:??:??}" ] && macaddr=${macaddr#??:}
    echo $macaddr
}

# Don't continue if we don't need network
[ -z "$netroot" ] && ! [ -e "/tmp/net.ifaces" ] && return;

# Write udev rules
{
    # bridge: attempt only the defined interface
    if [ -e /tmp/bridge.info ]; then
        . /tmp/bridge.info
        IFACES+=" ${ethnames%% *}"
    fi

    # bond: attempt only the defined interface (override bridge defines)
    if [ -e /tmp/bond.info ]; then
        . /tmp/bond.info
        # It is enough to fire up only one
        IFACES+=" ${bondslaves%% *}"
    fi

    if [ -e /tmp/vlan.info ]; then
        . /tmp/vlan.info
        IFACES+=" $phydevice"
    fi

    ifup='/sbin/ifup $env{INTERFACE}'
    [ -z "$netroot" ] && ifup="$ifup -m"

    # BOOTIF says everything, use only that one
    BOOTIF=$(getarg 'BOOTIF=')
    if [ -n "$BOOTIF" ] ; then
        BOOTIF=$(fix_bootif "$BOOTIF")
        printf 'ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="%s", RUN+="%s"\n' "$BOOTIF" "/sbin/initqueue --onetime $ifup"

    # If we have to handle multiple interfaces, handle only them.
    elif [ -n "$IFACES" ] ; then
        for iface in $IFACES ; do
            printf 'SUBSYSTEM=="net", ENV{INTERFACE}=="%s", RUN+="%s"\n' "$iface" "/sbin/initqueue --onetime $ifup"
        done

    # Default: We don't know the interface to use, handle all
    else
        printf 'SUBSYSTEM=="net", RUN+="%s"\n' "/sbin/initqueue --onetime $ifup" > /etc/udev/rules.d/61-default-net.rules
    fi

} > /etc/udev/rules.d/60-net.rules
