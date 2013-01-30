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
    # return macaddr with lowercase alpha characters expected by udev
    echo $macaddr | sed 'y/ABCDEF/abcdef/'
}

# Don't continue if we don't need network
if [ -z "$netroot" ] && [ ! -e "/tmp/net.ifaces" ] && ! getargbool 0 rd.neednet >/dev/null; then
    return
fi

# Write udev rules
{
    # bridge: attempt only the defined interface
    if [ -e /tmp/bridge.info ]; then
        . /tmp/bridge.info
        IFACES="$IFACES ${ethnames%% *}"
    fi

    # bond: attempt only the defined interface (override bridge defines)
    if [ -e /tmp/bond.info ]; then
        . /tmp/bond.info
        # It is enough to fire up only one
        IFACES="$IFACES ${bondslaves%% *}"
    fi

    if [ -e /tmp/team.info ]; then
        . /tmp/team.info
        IFACES="$IFACES ${teamslaves}"
    fi

    if [ -e /tmp/vlan.info ]; then
        . /tmp/vlan.info
        IFACES="$IFACES $phydevice"
    fi

    if [ -z "$IFACES" ]; then
        [ -e /tmp/net.ifaces ] && read IFACES < /tmp/net.ifaces
    fi

    if [ -e /tmp/net.bootdev ]; then
        bootdev=$(cat /tmp/net.bootdev)
    fi

    ifup='/sbin/ifup $env{INTERFACE}'
    [ -z "$netroot" ] && ifup="$ifup -m"

    # BOOTIF says everything, use only that one
    BOOTIF=$(getarg 'BOOTIF=')
    if [ -n "$BOOTIF" ] ; then
        BOOTIF=$(fix_bootif "$BOOTIF")
        printf 'ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="%s", RUN+="%s"\n' "$BOOTIF" "/sbin/initqueue --onetime $ifup"
        echo "[ -f /tmp/setup_net_${BOOTIF}.ok ]" >$hookdir/initqueue/finished/wait-${BOOTIF}.sh

    # If we have to handle multiple interfaces, handle only them.
    elif [ -n "$IFACES" ] ; then
        for iface in $IFACES ; do
            printf 'SUBSYSTEM=="net", ENV{INTERFACE}=="%s", RUN+="%s"\n' "$iface" "/sbin/initqueue --onetime $ifup"
            if [ "$bootdev" = "$iface" ]; then
                echo "[ -f /tmp/setup_net_${iface}.ok ]" >$hookdir/initqueue/finished/wait-$iface.sh
            fi
        done

    # Default: We don't know the interface to use, handle all
    # Fixme: waiting for the interface as well.
    else
        # if you change the name of "91-default-net.rules", also change modules.d/80cms/cmssetup.sh
        printf 'SUBSYSTEM=="net", RUN+="%s"\n' "/sbin/initqueue --onetime $ifup" > /etc/udev/rules.d/91-default-net.rules
    fi

# if you change the name of "90-net.rules", also change modules.d/80cms/cmssetup.sh
} > /etc/udev/rules.d/90-net.rules
