#!/bin/sh

[ -b /dev/mapper/$2 ] || exec /bin/plymouth ask-for-password --command="/sbin/cryptsetup luksOpen -T1 $1 $2"

