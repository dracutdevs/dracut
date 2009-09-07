#!/bin/sh
. /lib/dracut-lib.sh

if $UDEV_QUEUE_EMPTY >/dev/null 2>&1; then
    # run mdadm if udev has settled
    md=$1
    # and activate any containers
    mdadm -IR $md 2>&1 | vinfo
fi
