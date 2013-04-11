#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

if type plymouth >/dev/null 2>&1 && [ -z "$DRACUT_SYSTEMD" ]; then
    plymouth --newroot=$NEWROOT
fi
