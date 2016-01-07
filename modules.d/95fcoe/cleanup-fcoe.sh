#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

if [ -z "$DRACUT_SYSTEMD" ]; then
    if [ -e /var/run/lldpad.pid ]; then
        lldpad -k
    fi
fi
