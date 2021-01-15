#!/usr/bin/sh
# live images are specified with
# root=live:backingdev

isofile=$(getarg iso-scan/filename)

if [ -n "$isofile" ]; then
    /usr/sbin/initqueue --settled --unique /usr/sbin/iso-scan "$isofile"
fi
