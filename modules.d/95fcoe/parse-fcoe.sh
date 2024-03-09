#!/bin/sh
#
# Supported formats:
# fcoe=<networkdevice>:<dcb|nodcb>:<fabric|vn2vn>
# fcoe=<macaddress>:<dcb|nodcb>:<fabric|vn2vn>
#
# Note currently only nodcb is supported, the dcb option is reserved for
# future use.
#
# Note letters in the macaddress must be lowercase!
#
# Examples:
# fcoe=eth0:nodcb:vn2vn
# fcoe=4a:3f:4c:04:f8:d7:nodcb:fabric

if [ -z "$fcoe" ] && ! getarg fcoe=; then
    # If it's not set we don't continue
    return 0
fi

if ! getargbool 1 rd.fcoe -d -n rd.nofcoe; then
    info "rd.fcoe=0: skipping fcoe"
    return 0
fi

if ! [ -e /sys/bus/fcoe/ctlr_create ] && ! modprobe -b fcoe && ! modprobe -b libfcoe; then
    die "FCoE requested but kernel/initrd does not support FCoE"
fi

initqueue --onetime modprobe -b -q bnx2fc

parse_fcoe_opts() {
    local fcoe_interface
    local fcoe_dcb
    local fcoe_mode
    local fcoe_mac
    local OLDIFS="$IFS"
    local IFS=:
    # shellcheck disable=SC2086
    # shellcheck disable=SC2048
    set -- $*
    IFS="$OLDIFS"

    case $# in
        2)
            fcoe_interface=$1
            fcoe_dcb=$2
            fcoe_mode="fabric"
            unset fcoe_mac
            ;;
        3)
            fcoe_interface=$1
            fcoe_dcb=$2
            fcoe_mode=$3
            unset fcoe_mac
            ;;
        7)
            fcoe_mac=$(echo "$1:$2:$3:$4:$5:$6" | tr "[:upper:]" "[:lower:]")
            fcoe_dcb=$7
            fcoe_mode="fabric"
            unset fcoe_interface
            ;;
        8)
            fcoe_mac=$(echo "$1:$2:$3:$4:$5:$6" | tr "[:upper:]" "[:lower:]")
            fcoe_dcb=$7
            fcoe_mode=$8
            unset fcoe_interface
            ;;
        *)
            warn "Invalid arguments for fcoe=$fcoe"
            return 1
            ;;
    esac

    if [ "$fcoe_dcb" != "nodcb" -a "$fcoe_dcb" != "dcb" ]; then
        warn "Invalid FCoE DCB option: $fcoe_dcb"
    fi

    if [ "$fcoe_interface" = "edd" ]; then
        /sbin/initqueue --settled --unique /sbin/fcoe-edd "$fcoe_dcb"
        return 0
    fi

    if [ -z "$fcoe_interface" -a -z "$fcoe_mac" ]; then
        warn "fcoe: Neither interface nor MAC specified for fcoe=$fcoe"
        return 1
    fi

    {
        if [ -n "$fcoe_mac" ]; then
            # shellcheck disable=SC2016
            printf 'ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="%s", RUN+="/sbin/initqueue --onetime --unique --name fcoe-up-$name /sbin/fcoe-up $name %s %s"\n' "$fcoe_mac" "$fcoe_dcb" "$fcoe_mode"
            # shellcheck disable=SC2016
            printf 'ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="%s", RUN+="/sbin/initqueue --onetime --timeout --unique --name fcoe-timeout-$name /sbin/fcoe-up $name %s %s"\n' "$fcoe_mac" "$fcoe_dcb" "$fcoe_mode"
        else
            # shellcheck disable=SC2016
            printf 'ACTION=="add", SUBSYSTEM=="net", NAME=="%s", RUN+="/sbin/initqueue --onetime --unique --name fcoe-up-$name /sbin/fcoe-up $name %s %s"\n' "$fcoe_interface" "$fcoe_dcb" "$fcoe_mode"
            # shellcheck disable=SC2016
            printf 'ACTION=="add", SUBSYSTEM=="net", NAME=="%s", RUN+="/sbin/initqueue --onetime --timeout --unique --name fcoe-timeout-$name /sbin/fcoe-up $name %s %s"\n' "$fcoe_interface" "$fcoe_dcb" "$fcoe_mode"
        fi
    } >> /etc/udev/rules.d/92-fcoe.rules
}

for fcoe in $fcoe $(getargs fcoe=); do
    parse_fcoe_opts "$fcoe"
done
