#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

# called by dracut
check() {
    arch=$(uname -m)
    [ -x /sbin/zfcp_cio_free ] || return 1
    [ "$arch" = "s390" -o "$arch" = "s390x" ] || return 1

    return 0
}

# called by dracut
depends() {
    return 0
}

# called by dracut
installkernel() {
    instmods zfcp
}

# called by dracut
install() {
    inst_hook cmdline 30 "$moddir/parse-zfcp.sh"
    inst_multiple zfcp_cio_free grep sed seq

    inst_script /sbin/zfcpconf.sh
    inst_rules 56-zfcp.rules

    if [[ $hostonly ]]; then
        inst_simple /etc/zfcp.conf
    fi
}
