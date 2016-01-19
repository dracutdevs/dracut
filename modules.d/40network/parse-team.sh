#!/bin/sh
#
# Format:
#       team=<teammaster>:<teamslaves>
#
#       teamslaves is a comma-separated list of physical (ethernet) interfaces
#

parseteam() {
    local v=${1}:
    set --
    while [ -n "$v" ]; do
        set -- "$@" "${v%%:*}"
        v=${v#*:}
    done

    case $# in
    2)  teammaster=$1; teamslaves=$(str_replace "$2" "," " ") ;;
    *)  die "team= requires two parameters" ;;
    esac
}


for team in $(getargs team=); do
    unset teammaster teamslaves
    parseteam "$(getarg team=)"

    echo "teammaster=$teammaster" > /tmp/team.${teammaster}.info
    echo "teamslaves=\"$teamslaves\"" >> /tmp/team.${teammaster}.info
done
