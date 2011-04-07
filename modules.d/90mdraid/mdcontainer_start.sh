#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh

md=$1
udevadm control --stop-exec-queue
# and activate any containers
mdadm -IR $md 2>&1 | vinfo
ln -s $(command -v mdraid-cleanup) $hookdir/pre-pivot/30-mdraid-cleanup.sh 2>/dev/null
ln -s $(command -v mdraid-cleanup) $hookdir/pre-pivot/31-mdraid-cleanup.sh 2>/dev/null
udevadm control --start-exec-queue
