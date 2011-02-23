#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

root=$(getarg root=)

if rflags="$(getarg rootflags=)"; then
    getarg rw && rflags="${rflags},rw" || rflags="${rflags},ro"
else
    getarg rw && rflags=rw || rflags=ro
fi

fstype="$(getarg rootfstype=)"
if [ -z "$fstype" ]; then
    fstype="auto"
fi

