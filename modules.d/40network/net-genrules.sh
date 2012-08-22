#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

getargbool 0 rd.neednet && NEEDNET=1

# Don't continue if we don't need network
if [ -z "$netroot" ] && [ ! -e "/tmp/net.ifaces" ] && [ "$NEEDNET" != "1" ]; then
    return
fi

command -v fix_bootif >/dev/null || . /lib/net-lib.sh

# Write udev rules
{
    # bridge: attempt only the defined interface
    if [ -e /tmp/bridge.info ]; then
        . /tmp/bridge.info
        IFACES="$IFACES ${ethnames%% *}"
        MASTER_IFACES="$MASTER_IFACES $bridgename"
    fi

    # bond: attempt only the defined interface (override bridge defines)
    for i in /tmp/bond.*.info; do
        [ -e "$i" ] || continue
        unset bondslaves
        unset bondname
        . "$i"
        # It is enough to fire up only one
        IFACES="$IFACES ${bondslaves%% *}"
        MASTER_IFACES="$MASTER_IFACES ${bondname}"
    done

    if [ -e /tmp/team.info ]; then
        . /tmp/team.info
        IFACES="$IFACES ${teamslaves}"
        MASTER_IFACES="$MASTER_IFACES ${teammaster}"
    fi

    if [ -e /tmp/vlan.info ]; then
        . /tmp/vlan.info
        IFACES="$IFACES $phydevice"
        MASTER_IFACES="$MASTER_IFACES ${vlanname}"
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
            if [ "$bootdev" = "$iface" ] || [ "$NEEDNET" = "1" ]; then
                echo "[ -f /tmp/setup_net_${iface}.ok ]" >$hookdir/initqueue/finished/wait-$iface.sh
            fi
        done

        for iface in $MASTER_IFACES; do
            if [ "$bootdev" = "$iface" ] || [ "$NEEDNET" = "1" ]; then
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
