#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    arch=$(uname -m)
    [ "$arch" = "s390" -o "$arch" = "s390x" ] || return 1

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
    dracut_install tr

    inst /sbin/zfcpconf.sh
    inst_rules 56-zfcp.rules

    if [[ $hostonly ]]; then
        inst /etc/zfcp.conf
    fi
    dracut_install zfcp_cio_free grep sed seq
}