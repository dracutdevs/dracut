#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
for dasd_arg in $(getargs rd.dasd 'rd_DASD='); do
    (
        IFS=","
        set $dasd_arg
        echo "$@" >> /etc/dasd.conf
    )
done
