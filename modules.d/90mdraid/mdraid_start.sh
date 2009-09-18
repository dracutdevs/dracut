#!/bin/sh

. /lib/dracut-lib.sh
# run mdadm if udev has settled
info "Assembling MD RAID arrays"
udevadm control --stop-exec-queue
mdadm -IRs 2>&1 | vinfo
ln -s /sbin/mdraid-cleanup /pre-pivot/30-mdraid-cleanup.sh 2>/dev/null
ln -s /sbin/mdraid-cleanup /pre-pivot/31-mdraid-cleanup.sh 2>/dev/null
udevadm control --start-exec-queue
