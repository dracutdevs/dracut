#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    local _arch=$(uname -m)
    [ "$_arch" = "s390" -o "$_arch" = "s390x" ] || return 1
    require_binaries grep sed seq

    return 0
}

depends() {
    return 0
}

installkernel() {
    instmods dasd_mod dasd_eckd_mod dasd_fba_mod dasd_diag_mod
}

install() {
    inst_hook cmdline 31 "$moddir/parse-dasd-mod.sh"
    inst_multiple dasd_cio_free grep sed seq
}

