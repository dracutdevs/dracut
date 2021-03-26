#!/bin/sh
#
# Format:
#       team=<teammaster>:<teamslaves>[:<teamrunner>]
#
#       teamslaves is a comma-separated list of physical (ethernet) interfaces
#       teamrunner is the runner type to be used (see teamd.conf(5)); defaults to activebackup
#
#       team without parameters assumes team=team0:eth0,eth1:activebackup
#

parseteam() {
    local v=${1}:
    set --
    while [ -n "$v" ]; do
        set -- "$@" "${v%%:*}"
        v=${v#*:}
    done

    case $# in
        0)
            teammaster=team0
            teamslaves="eth0 eth1"
            teamrunner="activebackup"
            ;;
        1)
            teammaster=$1
            teamslaves="eth0 eth1"
            teamrunner="activebackup"
            ;;
        2)
            teammaster=$1
            teamslaves=$(str_replace "$2" "," " ")
            teamrunner="activebackup"
            ;;
        3)
            teammaster=$1
            teamslaves=$(str_replace "$2" "," " ")
            teamrunner=$3
            ;;
        *) die "team= requires zero to three parameters" ;;
    esac
    return 0
}

for team in $(getargs team); do
    [ "$team" = "team" ] && continue

    unset teammaster
    unset teamslaves
    unset teamrunner

    parseteam "$team" || continue

    {
        echo "teammaster=$teammaster"
        echo "teamslaves=\"$teamslaves\""
        echo "teamrunner=\"$teamrunner\""
    } > /tmp/team."${teammaster}".info

    if ! [ -e /etc/teamd/"${teammaster}".conf ]; then
        warn "Team master $teammaster specified, but no /etc/teamd/$teammaster.conf present. Using $teamrunner."
        mkdir -p /etc/teamd
        printf -- "%s" "{\"runner\": {\"name\": \"$teamrunner\"}, \"link_watch\": {\"name\": \"ethtool\"}}" > "/tmp/${teammaster}.conf"
    fi
done
