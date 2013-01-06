#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh
type det_fs >/dev/null 2>&1 || . /lib/fs-lib.sh

[ -f /etc/fstab ] && fstab_mount /etc/fstab

# prefer $NEWROOT/etc/fstab.sys over local /etc/fstab.sys
if [ -f $NEWROOT/etc/fstab.sys ]; then
    fstab_mount $NEWROOT/etc/fstab.sys
elif [ -f /etc/fstab.sys ]; then
    fstab_mount /etc/fstab.sys
fi
