#!/bin/sh
for dasd_arg in $(getargs rd.dasd= -d rd_DASD= DASD=); do
    IFS=","
    # shellcheck disable=SC2086
    echo $dasd_arg | normalize_dasd_arg >> /etc/dasd.conf
done
