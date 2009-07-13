#!/bin/sh

if $UDEV_QUEUE_EMPTY >/dev/null 2>&1; then
    [ -h "$job" ] && rm -f "$job"
    # run lvm scan if udev has settled
    lvm vgscan
    lvm vgchange -ay
fi

