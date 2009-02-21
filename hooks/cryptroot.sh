#!/bin/sh
[ -s /cryptroot ] && { 
    udevadm control --stop_exec_queue
    while read cryptopts; do
	/sbin/cryptsetup luksOpen $cryptopts
    done </cryptroot
    >/cryptroot
    udevadm control --start_exec_queue
    udevadm settle --timeout=30
}
