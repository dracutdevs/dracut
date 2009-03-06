#!/bin/sh
[ -s /cryptroot ] && { 
    udevadm control --stop-exec-queue
    while read cryptopts; do
       (   exec >/dev/console 2>&1 </dev/console
	   set $cryptopts
	   [ -b /dev/mapper/$2 ] || /bin/plymouth ask-for-password \
	       --command="/sbin/cryptsetup luksOpen -T1 $cryptopts"
       )
    done </cryptroot
    >/cryptroot
    udevadm control --start-exec-queue
    udevadm settle --timeout=30
}
