#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
for f in $hookdir/initqueue/settled/mdcontainer_start* $hookdir/initqueue/settled/mdraid_start* $hookdir/initqueue/settled/mdadm_auto*; do
    [ -e $f ] && return 1
done

$UDEV_QUEUE_EMPTY >/dev/null 2>&1 || return 1

return 0
