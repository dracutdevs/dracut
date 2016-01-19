#!/bin/sh

getargbool 0 rd.neednet && NEEDNET=1

# Don't continue if we don't need network
if [ -z "$netroot" ] && [ ! -e "/tmp/net.ifaces" ] && [ "$NEEDNET" != "1" ]; then
    return
fi

command -v fix_bootif >/dev/null || . /lib/net-lib.sh

# Write udev rules
{
    # bridge: attempt only the defined interface
    for i in /tmp/bridge.*.info; do
        [ -e "$i" ] || continue
        unset bridgeslaves
        unset bridgename
        . "$i"
        IFACES="$IFACES ${bridgeslaves%% *}"
        MASTER_IFACES="$MASTER_IFACES $bridgename"
    done

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

    for j in /tmp/vlan.*.phy; do
        [ -e "$j" ] || continue
        unset phydevice
        . "$j"
        for i in /tmp/vlan.*.${phydevice}; do
            [ -e "$i" ] || continue
            unset vlanname
            . "$i"
            IFACES="$IFACES $phydevice"
            MASTER_IFACES="$MASTER_IFACES ${vlanname}"
        done
    done

    if [ -z "$IFACES" ]; then
        [ -e /tmp/net.ifaces ] && read IFACES < /tmp/net.ifaces
    fi

    if [ -e /tmp/net.bootdev ]; then
        bootdev=$(cat /tmp/net.bootdev)
    fi

    ifup='/sbin/ifup $env{INTERFACE}'

    runcmd="RUN+=\"/sbin/initqueue --name ifup-\$env{INTERFACE} --unique --onetime $ifup\""

    # We have some specific interfaces to handle
    if [ -n "$IFACES" ]; then
        echo 'SUBSYSTEM!="net", GOTO="net_end"'
        echo 'ACTION!="add|change|move", GOTO="net_end"'
        for iface in $IFACES; do
            case "$iface" in
                ??:??:??:??:??:??)  # MAC address
                    cond="ATTR{address}==\"$iface\""
                    echo "$cond, $runcmd, GOTO=\"net_end\""
                    ;;
                ??-??-??-??-??-??)  # MAC address in BOOTIF form
                    cond="ATTR{address}==\"$(fix_bootif $iface)\""
                    echo "$cond, $runcmd, GOTO=\"net_end\""
                    ;;
                *)                  # an interface name
                    cond="ENV{INTERFACE}==\"$iface\""
                    echo "$cond, $runcmd, GOTO=\"net_end\""
                    cond="NAME==\"$iface\""
                    echo "$cond, $runcmd, GOTO=\"net_end\""
                    ;;
            esac
            # The GOTO prevents us from trying to ifup the same device twice
        done
        echo 'LABEL="net_end"'

        if [ -n "$MASTER_IFACES" ]; then
            wait_ifaces=$MASTER_IFACES
        else
            wait_ifaces=$IFACES
        fi

        for iface in $wait_ifaces; do
            if [ "$bootdev" = "$iface" ] || [ "$NEEDNET" = "1" ]; then
                echo "[ -f /tmp/net.${iface}.did-setup ]" >$hookdir/initqueue/finished/wait-$iface.sh
            fi
        done
    # Default: We don't know the interface to use, handle all
    # Fixme: waiting for the interface as well.
    else
        cond='ACTION=="add", SUBSYSTEM=="net"'
        # if you change the name of "91-default-net.rules", also change modules.d/80cms/cmssetup.sh
        echo "$cond, $runcmd" > /etc/udev/rules.d/91-default-net.rules
    fi

# if you change the name of "90-net.rules", also change modules.d/80cms/cmssetup.sh
} > /etc/udev/rules.d/90-net.rules
