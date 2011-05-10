#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

if [ -e /etc/multipath.conf ]; then
    HARD=""
    while pidof multipathd >/dev/null 2>&1; do
        for pid in $(pidof multipathd); do
            kill $HARD $pid >/dev/null 2>&1
        done
        HARD="-9"
    done
fi

