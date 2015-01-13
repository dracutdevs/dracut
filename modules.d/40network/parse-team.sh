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
        *)  warn "team= requires two parameters"; return 1;;
    esac
    return 0
}

unset teammaster teamslaves

if getarg team>/dev/null; then
    # Read team= parameters if they exist
    for team in $(getargs team); do
        [ "$team" = "team" ] && continue

        unset teammaster
        unset teamslaves

        parseteam "$team" || continue

        echo "teammaster=$teammaster" > /tmp/team.${teammaster}.info
        echo "teamslaves=\"$teamslaves\"" >> /tmp/team.${teammaster}.info

        if ! [ -e /etc/teamd/${teammaster}.conf ]; then
            warn "Team master $teammaster specified, but no /etc/teamd/$teammaster.conf present. Using activebackup."
            mkdir -p /etc/teamd
            printf -- "%s" '{"runner": {"name": "activebackup"}, "link_watch": {"name": "ethtool"}}' > "/etc/teamd/${teammaster}.conf"
        fi
    done
fi
