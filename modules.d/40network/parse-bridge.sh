#!/bin/sh
#
# Format:
#       bridge=<bridgename>:<bridgeslaves>
#
#       <bridgeslaves> is a comma-separated list of physical (ethernet) interfaces
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

    unset bridgename bridgeslaves
    case $# in
        0)  bridgename=br0; bridgeslaves=$iface ;;
        1)  die "bridge= requires two parameters" ;;
        2)  bridgename=$1; bridgeslaves=$(str_replace "$2" "," " ") ;;
        *)  die "bridge= requires two parameters" ;;
    esac
}

unset bridgename bridgeslaves

iface=eth0

# Parse bridge for bridgename and bridgeslaves
if bridge="$(getarg bridge)"; then
    # Read bridge= parameters if they exist
    if [ -n "$bridge" ]; then
        parsebridge $bridge
    fi
    # Simple default bridge
    if [ -z "$bridgename" ]; then
        bridgename=br0
        bridgeslaves=$iface
    fi
    echo "bridgename=$bridgename" > /tmp/bridge.info
    echo "bridgeslaves=\"$bridgeslaves\"" >> /tmp/bridge.info
    return
fi
