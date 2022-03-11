#!/bin/sh
# live images are specified with
# root=live:backingdev

isofile=$(getarg iso-scan/filename)
copytoram=$(getarg iso-scan.ram)

if [ -n "$isofile" ]; then
    /sbin/initqueue --settled --unique /sbin/iso-scan "$isofile" "$copytoram"
fi
