#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

create_udev_rule() {
    local ccw=$1
    local _drv _cu_type _dev_type
    local _rule=/etc/udev/rules.d/51-dasd-${ccw}.rules

    if [ -e /sys/bus/ccw/devices/${ccw} ] ; then
        read _cu_type < /sys/bus/ccw/devices/${ccw}/cutype
        read _dev_type < /sys/bus/ccw/devices/${ccw}/devtype
    fi
    case "$_cu_type" in
    3990/*|2105/*|2107/*|1750/*|9343/*)
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

    [ -e ${_rule} ] && return 0

    cat > $_rule <<EOF
ACTION=="add", SUBSYSTEM=="ccw", KERNEL=="$ccw", IMPORT{program}="collect $ccw %k ${ccw} $_drv"
ACTION=="add", SUBSYSTEM=="drivers", KERNEL=="$_drv", IMPORT{program}="collect $ccw %k ${ccw} $_drv"
ACTION=="add", ENV{COLLECT_$ccw}=="0", ATTR{[ccw/$ccw]online}="1"
EOF
}

for dasd_arg in $(getargs root=) $(getargs resume=); do
    (
        case $dasd_arg in
            /dev/disk/by-path/ccw-*)
                ccw_arg=${dasd_arg##*/}
                break;
        esac
        if [ -n "$ccw_arg" ] ; then
            IFS="-"
            set -- $ccw_arg
            create_udev_rule $2
        fi
    )
done
