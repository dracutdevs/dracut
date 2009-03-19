#!/bin/sh
exec >/dev/console 2>&1 </dev/console
[ -b /dev/mapper/$2 ] && exit 0
/bin/plymouth ask-for-password \
    --command="/sbin/cryptsetup luksOpen -T1 $1 $2"
