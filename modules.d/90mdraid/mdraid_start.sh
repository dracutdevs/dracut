#!/bin/sh

if $UDEV_QUEUE_EMPTY >/dev/null 2>&1; then
    [ -h "$job" ] && rm -f "$job"
    # run mdadm if udev has settled
    mdadm -IRs
fi

