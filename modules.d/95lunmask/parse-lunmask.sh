#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

create_udev_rule() {
    local transport=$1
    local tgtid=$2
    local lun=$3
    local _rule=/etc/udev/rules.d/51-${transport}-lunmask-${tgtid}.rules

    [ -e "${_rule}" ] && return 0

    if ! [ -f "$_rule" ]; then
        if [ "$transport" = "fc" ]; then
            printf 'ACTION=="add", SUBSYSTEM=="fc_remote_ports", ATTR{port_name}=="%s", PROGRAM="fc_transport_scan_lun.sh %s"\n' "$tgtid" "$lun" > "$_rule"
        elif [ "$transport" = "sas" ]; then
            printf 'ACTION=="add", SUBSYSTEM=="sas_device", ATTR{sas_address}=="%s", PROGRAM="sas_transport_scan_lun.sh %s"\n' "$tgtid" "$lun" > "$_rule"
        fi
    fi
}

for lunmask_arg in $(getargs rd.lunmask); do
    if [ -d /sys/module/scsi_mod ]; then
        printf "manual" > /sys/module/scsi_mod/parameters/scan
    elif ! [ -f /etc/modprobe.d/95lunmask.conf ]; then
        echo "options scsi_mod scan=manual" > /etc/modprobe.d/95lunmask.conf
    fi
    IFS=","
    create_udev_rule "$lunmask_arg"
done
