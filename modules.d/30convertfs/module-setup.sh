#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    [[ $mount_needs ]] && return 1
    return 255
}

depends() {
    return 0
}

install() {
    inst_multiple bash find ldconfig mv rm cp ln
    inst_hook pre-pivot 99 "$moddir/do-convertfs.sh"
    inst_script "$moddir/convertfs.sh" /usr/bin/convertfs
}

