#!/bin/sh

if $UDEV_QUEUE_EMPTY >/dev/null 2>&1; then
    [ -h "$job" ] && rm -f "$job"
    # run dmraid if udev has settled
    dmraid -ay 
fi

