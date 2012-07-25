#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

. /lib/dracut-lib.sh

for modlist in $(getargs rd.driver.post -d rdinsmodpost=); do
    (
        IFS=,
        for m in $modlist; do
            modprobe $m
        done
    )
done
