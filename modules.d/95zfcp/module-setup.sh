#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    arch=$(uname -m)
    [ "$arch" = "s390" -o "$arch" = "s390x" ] || return 1

    require_binaries zfcp_cio_free grep sed seq || return 1

    return 0
}

depends() {
    arch=$(uname -m)
    [ "$arch" = "s390" -o "$arch" = "s390x" ] || return 1

    return 0
}

installkernel() {
    instmods zfcp
}

install() {
    inst_hook cmdline 30 "$moddir/parse-zfcp.sh"
    inst_multiple zfcp_cio_free grep sed seq

    inst_script /sbin/zfcpconf.sh
    inst_rules 56-zfcp.rules

    if [[ $hostonly ]]; then
        inst_simple /etc/zfcp.conf
    fi
}
