#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

[ -x /bin/plymouth -a -z "$DRACUT_SYSTEMD" ] || exit 0
/bin/plymouth --newroot=$NEWROOT
