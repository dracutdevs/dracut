#!/bin/sh
#
# Format:
#       mptcp=<ifaces>:[options]
#
#       ifaces is a comma-separated list of interfaces
#       options is a comma-separated list on mptcp options
#

# Check if mptcp parameter is valid
if getarg mptcp= >/dev/null ; then
    :
fi

# We translate list of interfaces to space-separated here to mwke it easier to loop over them in ifup
parsemptcp() {
    local v=${1}:
    set --
    while [ -n "$v" ]; do
        set -- "$@" "${v%%:*}"
        v=${v#*:}
    done

    unset mptcpifaces mptcpoptions
    case $# in
    1)  mptcpifaces=$(str_replace "$1" "," " ") ;;
    2)  mptcpifaces=$(str_replace "$1" "," " ") ; mptcpoptions=$(str_replace "$2" "," " ") ;;
    *)  die "mptcp= requires one to two parameters" ;;
    esac
}

unset mptcpifaces mptcpoptions

# Parse mptcp for mptcpifaces mptcpoptions
if getarg mptcp >/dev/null; then
    # Read mptcp= parameters if they exist
    mptcp="$(getarg mptcp=)"
    if [ ! "$mptcp" = "mptcp" ]; then
        parsemptcp "$(getarg mptcp=)"
    fi
    # Make it suitable for initscripts export
    mptcpoptions=$(str_replace "$mptcpoptions" ";" ",")
    echo "mptcpifaces=\"$mptcpifaces\"" >> /tmp/mptcp.info
    echo "mptcpoptions=\"$mptcpoptions\"" >> /tmp/mptcp.info
    return
fi
