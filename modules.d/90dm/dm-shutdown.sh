#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
_do_dm_shutdown() {
    local ret
    local final=$1
    info "Disassembling device-mapper devices"
    dmsetup -v remove_all
    ret=$?
    if [ "x$final" != "x" ]; then
        info "dmsetup ls --tree"
        dmsetup ls --tree 2>&1 | vinfo
    fi
    return $ret
}
_do_dm_shutdown $1
