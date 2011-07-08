#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    [ "$1" = "-h" ] && {
        [ -x "/bin/keyctl" ] || return 1
    }

    return 0
}

depends() {
    return 0
}

installkernel() {
    instmods trusted encrypted
}

install() {
    inst keyctl
    inst uname
    inst_hook pre-pivot 60 "$moddir/masterkey.sh"
}
