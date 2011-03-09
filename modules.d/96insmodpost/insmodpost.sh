#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
. /lib/dracut-lib.sh

for p in $(getargs rd.insmodpost rdinsmodpost=); do 
    (
        IFS=,
        for p in $i; do 
            modprobe $p
        done
    )
done
