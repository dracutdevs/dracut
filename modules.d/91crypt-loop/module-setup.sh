#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

# called by dracut
check() {
    require_binaries losetup || return 1

    return 255
}

depends() {
    echo crypt
}

installkernel() {
    instmods loop
}

install() {
    inst_multiple losetup
    inst "$moddir/crypt-loop-lib.sh" "/lib/dracut-crypt-loop-lib.sh"
    dracut_need_initqueue
}
