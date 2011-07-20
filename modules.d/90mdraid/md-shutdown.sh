#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
_do_md_shutdown() {
    local ret
    info "Disassembling mdraid devices."
    mdadm -v --stop --scan 
    ret=$?
#info "cat /proc/mdstat"
#    cat /proc/mdstat | vinfo
    return $ret
}

_do_md_shutdown
