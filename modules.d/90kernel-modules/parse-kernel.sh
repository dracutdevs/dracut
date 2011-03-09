#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

for p in $(getargs rd.loaddriver rdloaddriver=); do 
    ( 
        IFS=,
        for p in $i; do 
            modprobe $p 2>&1 | vinfo
        done
    )
done

