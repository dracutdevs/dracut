#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
mod_args=""
for dasd_arg in $(getargs rd.dasd= rd_DASD= DASD=); do
    if [ -z $mod_args ]; then
        mod_args="$dasd_arg"
    else
        # We've already got some thing in mod_args, add to it
        mod_args="$mod_args,$dasd_arg"
    fi
done

if [ ! -z $mod_args ]; then
    [ -d /etc/modprobe.d ] || mkdir -m 0755 -p /etc/modprobe.d
    echo "options dasd_mod dasd=$mod_args" >> /etc/modprobe.d/dasd_mod.conf
fi

unset dasd_arg
dasd_cio_free
