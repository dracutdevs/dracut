#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
_do_md_shutdown() {
    local ret
    local final=$1
    local _offroot=$(strstr "$(mdadm --help-options 2>&1)" offroot && echo --offroot)
    info "Disassembling mdraid devices."
    mdadm $_offroot -v --stop --scan
    ret=$?
    if [ "x$final" != "x" ]; then
        info "cat /proc/mdstat"
        cat /proc/mdstat | vinfo
    fi
    return $ret
}

_do_md_shutdown $1
