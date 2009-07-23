#!/bin/sh
#
# Format:
#	bridge=<bridgename>:<ethname>
#
#	bridge without parameters assumes bridge=br0:eth0
#

# return if bridge already parsed
[ -n "$bridgename" ] && return

# Check if bridge parameter is valid 
if getarg ip= >/dev/null ; then
    if [ -z "$netroot" ] ; then
	die "No netboot configured, bridge is invalid"
    fi
fi

parsebridge() {
    local v=${1}:
    set --
    while [ -n "$v" ]; do
        set -- "$@" "${v%%:*}"
        v=${v#*:}
    done

    unset bridgename ethname
    case $# in
    0)  bridgename=br0; ethname=eth0 ;;
    1)  die "bridge= requires two parameters" ;;
    2)  bridgename=$1; ethname=$2 ;;
    *)  die "bridge= requires two parameters" ;;
    esac
}

unset bridgename ethname

# Parse bridge for bridgename and ethname
if getarg bridge >/dev/null; then
    initrdargs="$initrdargs bridge" 
    # Read bridge= parameters if they exist
    bridge="$(getarg bridge=)"
    if [ ! "$bridge" = "bridge" ]; then 
        parsebridge "$(getarg bridge=)"
    fi
    # Simple default bridge
    if [ -z "$bridgename" ]; then
        bridgename=br0
        ethname=eth0
    fi
    echo "bridgename=$bridgename" > /tmp/bridge.info
    echo "ethname=$ethname" >> /tmp/bridge.info
    return
fi
