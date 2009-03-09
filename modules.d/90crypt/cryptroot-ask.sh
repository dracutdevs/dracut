#!/bin/sh

[ -b /dev/mapper/$2 ] && exit 0
(
	flock -s 200
	/sbin/cryptsetup luksOpen -T1 $1 $2 </dev/console >/dev/console 2>&1
) 200>/.console.lock

