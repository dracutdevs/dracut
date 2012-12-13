#!/bin/sh
#
# Format:
#       team=<teammaster>:<teamslaves>
#
#       teamslaves is a comma-separated list of physical (ethernet) interfaces
#

# return if team already parsed
[ -n "$teammaster" ] && return

# Check if team parameter is valid
if getarg team= >/dev/null ; then
    :
fi

parseteam() {
    local v=${1}:
    set --
    while [ -n "$v" ]; do
        set -- "$@" "${v%%:*}"
        v=${v#*:}
    done

    unset teammaster teamslaves
    case $# in
    2)  teammaster=$1; teamslaves=$(str_replace "$2" "," " ") ;;
    *)  die "team= requires two parameters" ;;
    esac
}

unset teammaster teamslaves

if getarg team>/dev/null; then
    # Read team= parameters if they exist
    team="$(getarg team=)"
    if [ ! "$team" = "team" ]; then
        parseteam "$(getarg team=)"
    fi

    echo "teammaster=$teammaster" > /tmp/team.info
    echo "teamslaves=\"$teamslaves\"" >> /tmp/team.info
    return
fi
