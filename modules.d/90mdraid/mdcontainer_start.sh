#!/bin/sh
. /lib/dracut-lib.sh

md=$1
udevadm control --stop-exec-queue
# and activate any containers
mdadm -IR $md 2>&1 | vinfo
ln -s /sbin/mdraid-cleanup /pre-pivot/30-mdraid-cleanup.sh 2>/dev/null
ln -s /sbin/mdraid-cleanup /pre-pivot/31-mdraid-cleanup.sh 2>/dev/null
udevadm control --start-exec-queue
