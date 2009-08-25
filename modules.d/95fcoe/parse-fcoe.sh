#!/bin/sh
#
# Supported formats:
# fcoe=<networkdevice>:<dcb|nodcb>
# fcoe=<macaddress>:<dcb|nodcb>
#
# Note currently only nodcb is supported, the dcb option is reserved for
# future use.
#
# Note letters in the macaddress must be lowercase!
#
# Examples:
# fcoe=eth0:nodcb
# fcoe=4A:3F:4C:04:F8:D7:nodcb

[ -z "$fcoe" ] && fcoe=$(getarg fcoe=)

# If it's not set we don't continue
[ -z "$fcoe" ] && return

parse_fcoe_opts() {
    local IFS=:
    set $fcoe

    case $# in
        2)
            fcoe_interface=$1
            fcoe_dcb=$2
            ;;
        7)
            fcoe_mac=$1:$2:$3:$4:$5:$6
            fcoe_dcb=$7
            ;;
        *)
            die "Invalid arguments for fcoe="
            ;;
    esac
}

parse_fcoe_opts

# currently only nodcb is supported
if [ "$fcoe_dcb" != "nodcb" ] ; then
    die "Invalid FCoE DCB option: $fcoe_dcb"
fi

# FCoE actually supported?
[ -e /sys/module/fcoe/parameters/create ] || modprobe fcoe || die "FCoE requested but kernel/initrd does not support FCoE"
