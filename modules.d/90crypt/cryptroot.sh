#!/bin/sh
exec >/dev/console 2>&1 </dev/console
[ -b /dev/mapper/$2 ] && exit 0
/sbin/cryptsetup -T 3 -t 30 luksOpen $1 $2
