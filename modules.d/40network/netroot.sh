#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

PATH=/usr/sbin:/usr/bin:/sbin:/bin
type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh

# Huh? Empty $1?
[ -z "$1" ] && exit 1

# Huh? No interface config?
[ ! -e /tmp/net.$1.up ] && exit 1

# [ ! -z $2 ] means this is for manually bringing up network
# instead of real netroot; If It's called without $2, then there's
# no sense in doing something if no (net)root info is available
# or root is already there
if [ -z "$2" ]; then
    [ -d $NEWROOT/proc ] && exit 0
    [ -z "$netroot" ] && exit 1
fi

# Let's see if we have to wait for other interfaces
# Note: exit works just fine, since the last interface to be
#       online'd should see all files
[ -e "/tmp/net.ifaces" ] && read IFACES < /tmp/net.ifaces
for iface in $IFACES ; do
    [ -e /tmp/net.$iface.up ] || exit 1
done

# Set or override primary interface
netif=$1
[ -e "/tmp/net.bootdev" ] && read netif < /tmp/net.bootdev

if [ -e /tmp/net.$netif.manualup ]; then
    rm -f /tmp/net.$netif.manualup
fi

# Figure out the handler for root=dhcp by recalling all netroot cmdline
# handlers when this is not called from manually network bringing up.
if [ -z "$2" ]; then
    if [ "$netroot" = "dhcp" ] || [ "$netroot" = "dhcp6" ] ; then
        # Unset root so we can check later
        unset root

        # Load dhcp options
        [ -e /tmp/dhclient.$netif.dhcpopts ] && . /tmp/dhclient.$netif.dhcpopts

        # If we have a specific bootdev with no dhcpoptions or empty root-path,
        # we die. Otherwise we just warn
        if [ -z "$new_root_path" ] ; then
            [ -n "$BOOTDEV" ] && die "No dhcp root-path received for '$BOOTDEV'"
            warn "No dhcp root-path received for '$BOOTDEV' trying other interfaces if available"
            exit 1
        fi

        # Set netroot to new_root_path, so cmdline parsers don't call
        netroot=$new_root_path

        # FIXME!
        for f in $hookdir/cmdline/90*.sh; do
            [ -f "$f" ] && . "$f";
        done
    else
        rootok="1"
    fi

    # Check: do we really know how to handle (net)root?
    [ -z "$root" ] && die "No or empty root= argument"
    [ -z "$rootok" ] && die "Don't know how to handle 'root=$root'"

    handler=${netroot%%:*}
    handler=${handler%%4}
    handler=$(command -v ${handler}root)
    if [ -z "$netroot" ] || [ ! -e "$handler" ] ; then
        die "No handler for netroot type '$netroot'"
    fi
fi

# We're here, so we can assume that upping interfaces is now ok
[ -z "$IFACES" ] && IFACES="$netif"
for iface in $IFACES ; do
    . /tmp/net.$iface.up
done

[ -e /tmp/net.$netif.gw ]          && . /tmp/net.$netif.gw
[ -e /tmp/net.$netif.hostname ]    && . /tmp/net.$netif.hostname
[ -e /tmp/net.$netif.resolv.conf ] && cp -f /tmp/net.$netif.resolv.conf /etc/resolv.conf

# Load interface options
[ -e /tmp/net.$netif.override ] && . /tmp/net.$netif.override
[ -e /tmp/dhclient.$netif.dhcpopts ] && . /tmp/dhclient.$netif.dhcpopts

# Handle STP Timeout: arping the default router if root server is
# unknown or not local, or if not available the root server.
# Note: This assumes that if no router is present the
# root server is on the same subnet.
#
# TODO There's some netroot variants that don't (yet) have their
# server-ip netroot

# Get router IP if set
[ -n "$new_routers" ] && gw_ip=${new_routers%%,*}
[ -n "$gw" ] && gw_ip=$gw
# Get root server IP if set
if [ -n "$netroot" ]; then
    dummy=${netroot#*:}
    dummy=${dummy%%:*}
    case "$dummy" in
        [0-9]*\.[0-9]*\.[0-9]*\.[0-9]*) netroot_ip=$dummy;;
    esac
fi
# Default arping dest to router
dest="$gw_ip"
# Change to arping root server if appropriate
if [ -n "$netroot_ip" ]; then
    if [ -z "$dest" ]; then
         # no gateway so check root server
        dest="$netroot_ip"
    else
        r=$(ip route get "$netroot_ip")
        if ! strstr "$r" ' via ' ; then
            # local root server, so don't arping gateway
            dest="$netroot_ip"
        fi
    fi
fi
if [ -n "$dest" ] && ! arping -q -f -w 60 -I $netif $dest ; then
    dinfo "Resolving $dest via ARP on $netif failed"
fi

# exit in case manually bring up network
[ -n "$2" ] && exit 0

# Source netroot hooks before we start the handler
source_all $hookdir/netroot

# Run the handler; don't store the root, it may change from device to device
# XXX other variables to export?
if $handler $netif $netroot $NEWROOT; then
    # Network rootfs mount successful
    for iface in $IFACES ; do
        [ -f /tmp/dhclient.$iface.lease ] &&    cp /tmp/dhclient.$iface.lease    /tmp/net.$iface.lease
        [ -f /tmp/dhclient.$iface.dhcpopts ] && cp /tmp/dhclient.$iface.dhcpopts /tmp/net.$iface.dhcpopts
    done

    # Save used netif for later use
    [ ! -f /tmp/net.ifaces ] && echo $netif > /tmp/net.ifaces
else
    warn "Mounting root via '$netif' failed"
    # If we're trying with multiple interfaces, put that one down.
    # ip down/flush ensures that routeing info goes away as well
    if [ -z "$BOOTDEV" ] ; then
        ip link set $netif down
        ip addr flush dev $netif
        echo "#empty" > /etc/resolv.conf
    fi
fi
exit 0
