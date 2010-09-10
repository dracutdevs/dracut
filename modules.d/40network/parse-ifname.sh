#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
#
# Format:
#       ifname=<interface>:<mac>
#
# Note letters in the macaddress must be lowercase!
#
# Examples:
# ifname=eth0:4a:3f:4c:04:f8:d7
#
# Note when using ifname= to get persistent interface names, you must specify
# an ifname= argument for each interface used in an ip= or fcoe= argument

# check if there are any ifname parameters
if ! getarg ifname= >/dev/null ; then
    return
fi

parse_ifname_opts() {
    local IFS=:
    set $1

    case $# in
        7)
            ifname_if=$1
            ifname_mac=$2:$3:$4:$5:$6:$7
            ;;
        *)
            die "Invalid arguments for ifname="
            ;;
    esac
}

# Check ifname= lines
for p in $(getargs ifname=); do
    parse_ifname_opts $p
done
