#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
#
# Format:
#       bridge=<bridgename>:<ethnames>
#
#       <ethnames> is a comma-separated list of physical (ethernet) interfaces
#       bridge without parameters assumes bridge=br0:eth0
#

# return if bridge already parsed
[ -n "$bridgename" ] && return

# Check if bridge parameter is valid
if getarg bridge= >/dev/null ; then
    command -v brctl >/dev/null 2>&1 || die "No 'brctl' installed" 
fi

parsebridge() {
    local v=${1}:
    set --
    while [ -n "$v" ]; do
        set -- "$@" "${v%%:*}"
        v=${v#*:}
    done

    unset bridgename ethnames
    case $# in
        0)  bridgename=br0; ethnames=$iface ;;
        1)  die "bridge= requires two parameters" ;;
        2)  bridgename=$1; ethnames=$(str_replace "$2" "," " ") ;;
        *)  die "bridge= requires two parameters" ;;
    esac
}

unset bridgename ethnames

iface=eth0
if [ -e /tmp/bond.info ]; then
    . /tmp/bond.info
    if [ -n "$bondname" ] ; then
        iface=$bondname
    fi
fi

# Parse bridge for bridgename and ethnames
if bridge="$(getarg bridge)"; then
    # Read bridge= parameters if they exist
    if [ -n "$bridge" ]; then
        parsebridge $bridge
    fi
    # Simple default bridge
    if [ -z "$bridgename" ]; then
        bridgename=br0
        ethnames=$iface
    fi
    echo "bridgename=$bridgename" > /tmp/bridge.info
    echo "ethnames=\"$ethnames\"" >> /tmp/bridge.info
    return
fi
