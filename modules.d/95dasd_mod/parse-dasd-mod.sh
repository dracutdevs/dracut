#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
mod_args=""

convert_dasd_param() {
    local bus_id params
    params=""
    bus_id=$1; shift
    while [ $# -gt 0 ]; do
        case "$1" in
            use_diag\=1)
                params="$params,diag"
                ;;
            readonly\=1)
                params="$params,ro"
                ;;
            erplog\=1)
                params="$params,erplog"
                ;;
            failfast\=1)
                params="$params,failfast"
                ;;
        esac
        shift
    done
    params="${params#*,}"
    if [ -n "$params" ]; then
        echo "$bus_id($params)"
    else
        echo "$bus_id"
    fi
}

for dasd_arg in $(getargs rd.dasd= rd_DASD= DASD=); do
    OLD_IFS=$IFS
    IFS=","
    set -- $dasd_arg
    IFS=$OLD_IFS
    dasd_arg=$(convert_dasd_param "$@")
    mod_args="$mod_args,$dasd_arg"
done

mod_args="${mod_args#*,}"

if [ -n "$mod_args" ]; then
    [ -d /etc/modprobe.d ] || mkdir -m 0755 -p /etc/modprobe.d
    echo "options dasd_mod dasd=$mod_args" >> /etc/modprobe.d/dasd_mod.conf
fi

unset dasd_arg
dasd_cio_free
