#!/bin/sh
[ -s /cryptroot ] && { 
    udevadm control --stop_exec_queue
    while read cryptopts; do
       (   exec >/dev/console 2>&1 </dev/console
           /sbin/cryptsetup luksOpen $cryptopts || emergency_shell
       )
    done </cryptroot
    >/cryptroot
    udevadm control --start_exec_queue
    udevadm settle --timeout=30
}
