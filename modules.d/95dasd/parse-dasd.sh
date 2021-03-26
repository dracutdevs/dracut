#!/bin/sh
for dasd_arg in $(getargs rd.dasd= -d rd_DASD= DASD=); do
    (
        local OLDIFS="$IFS"
        IFS=","
        # shellcheck disable=SC2086
        set -- $dasd_arg
        IFS="$OLDIFS"
        echo "$@" | normalize_dasd_arg >> /etc/dasd.conf
    )
done
