#!/bin/sh
[ -s /cryptroot ] && { 
    udevadm control --stop-exec-queue
    while read cryptopts; do
       (   exec >/dev/console 2>&1 </dev/console
           /sbin/cryptsetup luksOpen $cryptopts || emergency_shell
       )
    done </cryptroot
    >/cryptroot
    udevadm control --start-exec-queue
    udevadm settle --timeout=30
}
