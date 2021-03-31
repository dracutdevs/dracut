#!/bin/sh
#
# Preferred format:
#       root=nbd:srv:port/exportname[:fstype[:rootflags[:nbdopts]]]
#       [root=*] netroot=nbd:srv:port/exportname[:fstype[:rootflags[:nbdopts]]]
#
# nbdopts is a comma separated list of options to give to nbd-client
#
# root= takes precedence over netroot= if root=nbd[...]
#

# This script is sourced, so root should be set. But let's be paranoid
[ -z "$root" ] && root=$(getarg root=)

if [ -z "$netroot" ]; then
    for netroot in $(getargs netroot=); do
        [ "${netroot%%:*}" = "nbd" ] && break
    done
    [ "${netroot%%:*}" = "nbd" ] || unset netroot
fi

# Root takes precedence over netroot
if [ "${root%%:*}" = "nbd" ]; then
    if [ -n "$netroot" ]; then
        warn "root takes precedence over netroot. Ignoring netroot"

    fi
    netroot=$root
    unset root
fi

# If it's not nbd we don't continue
[ "${netroot%%:*}" = "nbd" ] || return

# Check required arguments
nroot=${netroot#nbd:}
server=${nroot%%:*}
if [ "${server%"${server#?}"}" = "[" ]; then
    server=${nroot#[}
    server=${server%%]:*}\]
    nroot=${nroot#*]:}
else
    nroot=${nroot#*:}
fi
port=${nroot%%:*}
unset nroot

[ -z "$server" ] && die "Argument server for nbdroot is missing"
[ -z "$port" ] && die "Argument port for nbdroot is missing"

# NBD actually supported?
incol2 /proc/devices nbd || modprobe nbd || die "nbdroot requested but kernel/initrd does not support nbd"

# Done, all good!
# shellcheck disable=SC2034
rootok=1

# Shut up init error check
if [ -z "$root" ]; then
    root=block:/dev/root
    # the device is created and waited for in ./nbdroot.sh
fi

echo 'nbd-client -check /dev/nbd0 > /dev/null 2>&1' > "$hookdir"/initqueue/finished/nbdroot.sh
