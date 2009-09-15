#!/bin/sh

# Don't continue if root is ok
[ -n "$rootok" ] && return

# This script is sourced, so root should be set. But let's be paranoid
[ -z "$root" ] && root=$(getarg root=)
[ -z "$netroot" ] && netroot=$(getarg netroot=)

if [ "$root" = "dhcp" ] || [ "$netroot" = "dhcp" ] ; then
    # Tell ip= checker that we need dhcp
    NEEDDHCP="1"

    # Done, all good!
    rootok=1
    netroot=dhcp

    # Shut up init error check
    [ -z "$root" ] && root="dhcp"
    echo '[ -d $NEWROOT/proc -o -e /dev/root ]' > /initqueue-finished/dhcp.sh
fi
