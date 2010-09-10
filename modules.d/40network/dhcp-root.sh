#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

# Don't continue if root is ok
[ -n "$rootok" ] && return

# This script is sourced, so root should be set. But let's be paranoid
[ -z "$root" ] && root=$(getarg root=)
[ -z "$netroot" ] && netroot=$(getarg netroot=)

if [ "$root" = "dhcp" ] || [ "$root" = "dhcp6" ] || [ "$netroot" = "dhcp" ] ; then
    # Tell ip= checker that we need dhcp
    NEEDDHCP="1"

    # Done, all good!
    rootok=1
    if [ "$netroot" != "dhcp" ] ; then
        netroot=$root
    fi

    # Shut up init error check
    [ -z "$root" ] && root="dhcp"
    echo '[ -d $NEWROOT/proc -o -e /dev/root ]' > /initqueue-finished/dhcp.sh
fi
