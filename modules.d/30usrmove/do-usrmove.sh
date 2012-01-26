#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

if getargbool 0 rd.usrmove; then
    if getargbool 0 rd.debug; then
        bash -x usrmove-convert "$NEWROOT" 2>&1 | vinfo
    else
        usrmove-convert "$NEWROOT" 2>&1 | vinfo
    fi
fi
