#!/bin/sh
#
# Format:
#       mptcp=<mptcpifaces>
#
#       mptcpifaces is a comma-separated list of interfaces
#

# return if team already parsed
[ -n "$mptcpifaces" ] && return

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

    unset mptcpifaces
    case $# in
    1)  mptcpifaces=$(str_replace "$1" "," " ") ;;
    *)  die "mptcp= requires one parameter with list of interfaces" ;;
    esac
}

unset mptcpifaces

# Parse mptcp for mptcpifaces
if getarg mptcp >/dev/null; then
    # Read mptcp= parameters if they exist
    mptcp="$(getarg mptcp=)"
    if [ ! "$mptcp" = "mptcp" ]; then
        parsemptcp "$(getarg mptcp=)"
    fi
    # Make it suitable for initscripts export
    echo "mptcpifaces=\"$mptcpifaces\"" >> /tmp/mptcp.info
    return
fi
