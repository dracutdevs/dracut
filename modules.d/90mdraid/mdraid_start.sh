#!/bin/sh

. /lib/dracut-lib.sh
# run mdadm if udev has settled
info "Assembling MD RAID arrays"
udevadm control --stop-exec-queue
mdadm -IRs 2>&1 | vinfo
udevadm control --start-exec-queue
