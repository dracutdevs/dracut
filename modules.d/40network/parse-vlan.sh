#!/bin/sh
#
# Format:
#	vlan=<vlanname>:<phydevice>
#

# return if vlan already parsed
[ -n "$vlanname" ] && return

# Check if vlan parameter is valid
if getarg vlan= >/dev/null ; then
    :
fi

parsevlan() {
    local v=${1}:
    set --
    while [ -n "$v" ]; do
        set -- "$@" "${v%%:*}"
        v=${v#*:}
    done

    unset vlanname phydevice
    case $# in
    2)  vlanname=$1; phydevice=$2 ;;
    *)  die "vlan= requires two parameters" ;;
    esac
}

unset vlanname phydevice

if getarg vlan >/dev/null; then
    # Read vlan= parameters if they exist
    vlan="$(getarg vlan=)"
    if [ ! "$vlan" = "vlan" ]; then
        parsevlan "$(getarg vlan=)"
    fi

    echo "$phydevice" > /tmp/vlan.${phydevice}.phy
    echo "$vlanname" > /tmp/vlan.${vlanname}.${phydevice}
    return
fi
