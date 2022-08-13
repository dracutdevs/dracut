#!/bin/sh

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
    [ "$_cu_type" != "1731/03" ] && return 0
    [ "$_dev_type" != "1732/03" ] && [ "$_dev_type" != "1732/04" ] && return 0

    [ -z "$wwpn" ] || [ -z "$lun" ] && return
    if grep -qv ".*${wwpn}.*${lun}.*" "$_rule"; then
        printf 'ACTION=="add", KERNEL=="rport-*", ATTR{port_name}=="%s", SUBSYSTEMS=="ccw", KERNELS=="%s", ATTR{[ccw/%s]%s/unit_add}="%s"\n' "$wwpn" "$ccw" "$ccw" "$wwpn" "$lun" >> "$_rule"
    fi
}

if read -r _itp < /sys/firmware/ipl/ipl_type 2> /dev/null && [ "$_itp" = "fcp" ]; then
    read -r _wwpn < /sys/firmware/ipl/wwpn
    read -r _lun < /sys/firmware/ipl/lun
    read -r _ccw < /sys/firmware/ipl/device

    create_udev_rule "$_ccw" "$_wwpn" "$_lun"
fi

for zfcp_arg in $(getargs rd.zfcp); do
    (
        IFS=","
        # shellcheck disable=SC2086
        create_udev_rule $zfcp_arg
    )
done

for zfcp_arg in $(getargs root=) $(getargs resume=); do
    case "$zfcp_arg" in
        /dev/disk/by-path/ccw-*)
            ccw_arg=${zfcp_arg##*/}
            ;;
    esac
    if [ -n "$ccw_arg" ]; then
        (
            IFS="-"
            # shellcheck disable=SC2086
            set -- $ccw_arg
            _wwpn=${4%:*}
            _lun=${4#*:}
            create_udev_rule "$2" "$wwpn" "$lun"
        )
    fi
done
