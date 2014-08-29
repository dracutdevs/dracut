#!/bin/sh
for dasd_arg in $(getargs rd.dasd= -d rd_DASD= DASD=); do
    (
        IFS=","
        set -- $dasd_arg
        echo "$@" | normalize_dasd_arg >> /etc/dasd.conf
    )
done
