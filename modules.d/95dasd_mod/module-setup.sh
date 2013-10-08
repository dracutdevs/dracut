#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

# called by dracut
check() {
    local _arch=$(uname -m)
    [ "$_arch" = "s390" -o "$_arch" = "s390x" ] || return 1

    return 0
}

# called by dracut
depends() {
    return 0
}

# called by dracut
installkernel() {
    instmods dasd_mod dasd_eckd_mod dasd_fba_mod dasd_diag_mod
}

# called by dracut
install() {
    inst_hook cmdline 31 "$moddir/parse-dasd-mod.sh"
    inst_multiple dasd_cio_free grep sed seq
}

