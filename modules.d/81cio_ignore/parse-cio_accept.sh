#!/usr/bin/sh

CIO_IGNORE=$(getarg cio_ignore)
CIO_ACCEPT=$(getarg rd.cio_accept)

if [ -z $CIO_IGNORE ] ; then
    info "cio_ignored disabled on commandline"
    return
fi
if [ -n "$CIO_ACCEPT" ] ; then
    OLDIFS="$IFS"
    IFS=,
    set -- $CIO_ACCEPT
    while (($# > 0)) ; do
        info "Enabling device $1"
        cio_ignore --remove $1
        shift
    done
    IFS="$OLDIFS"
fi
