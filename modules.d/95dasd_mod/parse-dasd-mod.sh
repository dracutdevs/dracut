#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
[ -d /etc/modprobe.d ] || mkdir -m 0755 -p /etc/modprobe.d

dasd_arg=$(getarg rd.dasd_mod.dasd rd_DASD_MOD=)
if [ -n "$dasd_arg" ]; then
    echo "options dasd_mod dasd=$dasd_arg" >> /etc/modprobe.d/dasd_mod.conf
fi
unset dasd_arg

dasd_cio_free
