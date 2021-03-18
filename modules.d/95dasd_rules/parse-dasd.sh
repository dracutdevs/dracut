#!/bin/bash

create_udev_rule() {
    local ccw=$1
    local _drv _cu_type _dev_type
    local _rule="/etc/udev/rules.d/51-dasd-${ccw}.rules"

    if [ -x /sbin/cio_ignore ] && cio_ignore -i "$ccw" > /dev/null; then
        cio_ignore -r "$ccw"
    fi

    if [ -e /sys/bus/ccw/devices/"${ccw}" ]; then
        read -r _cu_type < /sys/bus/ccw/devices/"${ccw}"/cutype
        read -r _dev_type < /sys/bus/ccw/devices/"${ccw}"/devtype
    fi

    case "$_cu_type" in
        3990/* | 2105/* | 2107/* | 1750/* | 9343/*)
            _drv=dasd-eckd
            ;;
        6310/*)
            _drv=dasd-fba
            ;;
        3880/*)
            case "$_dev_type" in
                3380/*)
                    _drv=dasd_eckd
                    ;;
                3370/*)
                    _drv=dasd-fba
                    ;;
            esac
            ;;
    esac
    [ -z "${_drv}" ] && return 0

    [ -e "${_rule}" ] && return 0

    cat > "$_rule" << EOF
ACTION=="add", SUBSYSTEM=="ccw", KERNEL=="$ccw", IMPORT{program}="collect $ccw %k ${ccw} $_drv"
ACTION=="add", SUBSYSTEM=="drivers", KERNEL=="$_drv", IMPORT{program}="collect $ccw %k ${ccw} $_drv"
ACTION=="add", ENV{COLLECT_$ccw}=="0", ATTR{[ccw/$ccw]online}="1"
EOF
}

if [[ -f /sys/firmware/ipl/ipl_type ]] && [[ $(< /sys/firmware/ipl/ipl_type) == "ccw" ]]; then
    create_udev_rule "$(< /sys/firmware/ipl/device)"
fi

for dasd_arg in $(getargs root=) $(getargs resume=); do
    [[ $dasd_arg =~ /dev/disk/by-path/ccw-* ]] || continue

    ccw_dev="${dasd_arg##*/ccw-}"
    create_udev_rule "${ccw_dev%%-*}"
done

for dasd_arg in $(getargs rd.dasd=); do
    IFS=',' read -r -a devs <<< "$dasd_arg"
    declare -p devs
    for dev in "${devs[@]}"; do
        case "$dev" in
            autodetect | probeonly) ;;

            *-*)
                IFS="-" read -r start end _ <<< "${dev%(ro)}"
                prefix=${start%.*}
                start=${start##*.}
                for rdev in $(seq $((16#$start)) $((16#$end))); do
                    create_udev_rule "$(printf "%s.%04x" "$prefix" "$rdev")"
                done
                ;;
            *)
                IFS="." read -r sid ssid chan _ <<< "${dev%(ro)}"
                create_udev_rule "$(printf "%01x.%01x.%04x" $((16#$sid)) $((16#$ssid)) $((16#$chan)))"
                ;;
        esac
    done
done
