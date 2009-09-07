#!/bin/sh
. /lib/dracut-lib.sh

md=$1
# and activate any containers
mdadm -IR $md 2>&1 | vinfo
