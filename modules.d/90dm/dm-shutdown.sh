#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
_do_dm_shutdown() {
    local ret
    info "Disassembling device-mapper devices"
    dmsetup -v remove_all
    ret=$?
#info "dmsetup ls --tree"
#dmsetup ls --tree 2>&1 | vinfo
    return $ret
}

_do_dm_shutdown

