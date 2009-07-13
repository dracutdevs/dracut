#!/bin/sh

if udevadm settle --timeout=1 >/dev/null 2>&1; then
    [ -h "$job" ] && rm -f "$job"
    # run dmraid if udev has settled
    dmraid -ay -Z
fi

