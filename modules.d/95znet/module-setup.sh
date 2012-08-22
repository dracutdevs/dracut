#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    arch=$(uname -m)
    [ "$arch" = "s390" -o "$arch" = "s390x" ] || return 1

    return 0
}

depends() {
    return 0
}

installkernel() {
    instmods ctcm lcs qeth qeth_l2 qeth_l3
}

install() {
    inst_hook cmdline 30 "$moddir/parse-ccw.sh"
    inst_rules 81-ccw.rules
    dracut_install znet_cio_free grep sed seq readlink /lib/udev/ccw_init
}

