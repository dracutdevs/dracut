#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    [[ -d /etc/sysconfig/network-scripts ]] && return 0
    return 255
}

depends() {
    return 0
}

install() {
    inst_hook pre-pivot 85 "$moddir/write-ifcfg.sh"
}

