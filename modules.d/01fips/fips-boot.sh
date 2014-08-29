#!/bin/sh

if ! fipsmode=$(getarg fips) || [ $fipsmode = "0" ]; then
    rm -f -- /etc/modprobe.d/fips.conf >/dev/null 2>&1
elif getarg boot= >/dev/null; then
    . /sbin/fips.sh
    if mount_boot; then
        do_fips || die "FIPS integrity test failed"
    fi
fi
