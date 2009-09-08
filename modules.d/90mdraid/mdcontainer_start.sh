#!/bin/sh
. /lib/dracut-lib.sh

md=$1
udevadm control --stop-exec-queue
# and activate any containers
mdadm -IR $md 2>&1 | vinfo
udevadm control --start-exec-queue