#!/bin/sh

# Preferred format:
#       root=rbd:<mon>[,<mon2>,<mon3>]:<user>:<key>:<pool>:<image>[@<snapshot>]:[<part>]:[<mntopts>]
#       [root=*] netroot=rbd:<mon>[,<mon2>,<mon3>]:<user>:<key>:<pool>:<image>[@<snapshot>]:[<part>]:[<mntopts>]

netroot_to_var() {
    local v=${1}:
    set --
    while [ -n "$v" ]; do
        set -- "$@" "${v%%:*}"
        v=${v#*:}
    done

    unset mons user key pool image
    mons=$2; user=$3; key=$4; pool=$5; image=$6
}

# This script is sourced, so root should be set. But let's be paranoid
[ -z "$root" ] && root=$(getarg root=)

if [ -z "$netroot" ]; then
    for netroot in $(getargs netroot=); do
        [ "${netroot%%:*}" = "rbd" ] && break
    done
    [ "${netroot%%:*}" = "rbd" ] || unset netroot
fi

# Root takes precedence over netroot
if [ "${root%%:*}" = "rbd" ] ; then
    if [ -n "$netroot" ] ; then
        warn "root takes precedence over netroot. Ignoring netroot"

    fi
    netroot=$root
    unset root
fi

# If it's not rbd we don't continue
[ "${netroot%%:*}" = "rbd" ] || return

# Check required arguments
netroot_to_var $netroot
[ -z "$mons" ] && die "Argument mons for rbd root is missing"
[ -z "$user" ] && die "Argument user for rbd root is missing"
[ -z "$key" ] && die "Argument key for rbd root is missing"
[ -z "$pool" ] && die "Argument pool for rbd root is missing"
[ -z "$image" ] && die "Argument image for rb droot is missing"

# rbd actually supported?
incol2 /proc/devices rbd || modprobe rbd || die "rbd root requested but kernel/initrd does not support rbd"

# Done, all good!
rootok=1

echo '[ -e $NEWROOT/proc ]' > $hookdir/initqueue/finished/rbdroot.sh
