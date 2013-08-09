#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

for i in /dev/mapper/mpath*; do
    [ -b "$i" ] || continue
    need_shutdown
    break
done
