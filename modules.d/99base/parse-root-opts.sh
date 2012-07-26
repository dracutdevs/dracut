#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

root=$(getarg root=)

rflags="$(getarg rootflags=)"
getargbool 0 ro && rflags="${rflags},ro"
getargbool 0 rw && rflags="${rflags},rw"
rflags="${rflags#,}"

fstype="$(getarg rootfstype=)"
if [ -z "$fstype" ]; then
    fstype="auto"
fi

