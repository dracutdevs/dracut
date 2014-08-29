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
# fcoe=4a:3f:4c:04:f8:d7:nodcb

[ -z "$fcoe" ] && fcoe=$(getarg fcoe=)

# If it's not set we don't continue
[ -z "$fcoe" ] && return


# BRCM: Later, should check whether bnx2x is loaded first before loading bnx2fc so do not load bnx2fc when there are no Broadcom adapters
[ -e /sys/module/fcoe/parameters/create ] || modprobe -a fcoe || die "FCoE requested but kernel/initrd does not support FCoE"

modprobe bnx2fc >/dev/null 2>&1
udevadm settle --timeout=30

# FCoE actually supported?
[ -e /sys/module/fcoe/parameters/create ] || modprobe fcoe || die "FCoE requested but kernel/initrd does not support FCoE"

parse_fcoe_opts() {
    local IFS=:
    set $fcoe

    case $# in
        2)
            fcoe_interface=$1
            fcoe_dcb=$2
            return 0
            ;;
        7)
            fcoe_mac=$1:$2:$3:$4:$5:$6
            fcoe_dcb=$7
            return 0
            ;;
        *)
            warn "Invalid arguments for fcoe=$fcoe"
            return 1
            ;;
    esac
}

parse_fcoe_opts

if [ "$fcoe_interface" = "edd" ]; then
    if [ "$fcoe_dcb" != "nodcb" -a "$fcoe_dcb" != "dcb" ] ; then
        warn "Invalid FCoE DCB option: $fcoe_dcb"
    fi
    /sbin/initqueue --settled --unique /sbin/fcoe-edd $fcoe_dcb
else
    for fcoe in $(getargs fcoe=); do
        unset fcoe_mac
        unset fcoe_interface
        parse_fcoe_opts
        if [ "$fcoe_dcb" != "nodcb" -a "$fcoe_dcb" != "dcb" ] ; then
            warn "Invalid FCoE DCB option: $fcoe_dcb"
        fi
        . $(command -v fcoe-genrules.sh)
    done
fi
