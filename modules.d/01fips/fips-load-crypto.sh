#!/bin/sh

type getarg > /dev/null 2>&1 || . /lib/dracut-lib.sh

if ! fipsmode=$(getarg fips) || [ "$fipsmode" = "0" ]; then
    rm -f -- /etc/modprobe.d/fips.conf > /dev/null 2>&1
elif [ -z "$fipsmode" ]; then
    die "FIPS mode have to be enabled by 'fips=1' not just 'fips'"
else
    . /sbin/fips.sh
    fips_load_crypto || die "FIPS integrity test failed"
fi
