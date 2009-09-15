#!/bin/sh
. /lib/dracut-lib.sh

md=$1
udevadm control --stop-exec-queue
# and activate any containers
mdadm -IR $md 2>&1 | vinfo
[ -f /initqueue-settled/mdraid_start ] || rm /initqueue-finished/mdraid.sh 2>/dev/null
udevadm control --start-exec-queue
