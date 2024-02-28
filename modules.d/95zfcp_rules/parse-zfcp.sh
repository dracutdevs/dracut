#!/bin/bash

create_udev_rule() {
    local ccw=$1
    local wwpn=$2
    local lun=$3
    local _rule=/etc/udev/rules.d/51-zfcp-${ccw}.rules
    local _cu_type _dev_type

    if [ -x /sbin/cio_ignore ] && cio_ignore -i "$ccw" > /dev/null; then
        cio_ignore -r "$ccw"
    fi

    if [ -e /sys/bus/ccw/devices/"${ccw}" ]; then
        read -r _cu_type < /sys/bus/ccw/devices/"${ccw}"/cutype
        read -r _dev_type < /sys/bus/ccw/devices/"${ccw}"/devtype
    fi
    if [ "$_cu_type" != "1731/03" ]; then
        return 0
    fi
    if [ "$_dev_type" != "1732/03" ] && [ "$_dev_type" != "1732/04" ]; then
        return 0
    fi

    [ -z "$wwpn" ] || [ -z "$lun" ] && return
    m=$(sed -n "/.*${wwpn}.*${lun}.*/p" "$_rule")
    if [ -z "$m" ]; then
        cat >> "$_rule" << EOF
ACTION=="add", KERNEL=="rport-*", ATTR{port_name}=="$wwpn", SUBSYSTEMS=="ccw", KERNELS=="$ccw", ATTR{[ccw/$ccw]$wwpn/unit_add}="$lun"
EOF
    fi
}

if [[ -f /sys/firmware/ipl/ipl_type ]] \
    && [[ $(< /sys/firmware/ipl/ipl_type) == "fcp" ]]; then
    (
        read -r _wwpn < /sys/firmware/ipl/wwpn
        read -r _lun < /sys/firmware/ipl/lun
        read -r _ccw < /sys/firmware/ipl/device

        create_udev_rule "$_ccw" "$_wwpn" "$_lun"
    )
fi

for zfcp_arg in $(getargs rd.zfcp); do
    (
        OLDIFS="$IFS"
        IFS=","
        # shellcheck disable=SC2086
        set $zfcp_arg
        IFS="$OLDIFS"
        create_udev_rule "$1" "$2" "$3"
    )
done

for zfcp_arg in $(getargs root=) $(getargs resume=); do
    (
        case $zfcp_arg in
            /dev/disk/by-path/ccw-*)
                ccw_arg=${zfcp_arg##*/}
                ;;
        esac
        if [ -n "$ccw_arg" ]; then
            OLDIFS="$IFS"
            IFS="-"
            # shellcheck disable=SC2086
            set -- $ccw_arg
            IFS="$OLDIFS"
            _wwpn=${4%:*}
            _lun=${4#*:}
            create_udev_rule "$2" "$wwpn" "$lun"
        fi
    )
done
