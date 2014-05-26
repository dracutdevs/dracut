#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

# called by dracut
check() {
    require_binaries ip wc egrep sed grep || return 1
    return 0
}

# called by dracut
depends() {
    echo network
    return 0
}

# called by dracut
install() {
    for f in /etc/iproute2/*; do
        inst $f
    done
    inst_multiple ip egrep wc sed grep
    inst_hook cmdline 95 "$moddir/parse-mptcp.sh"
    inst_script "$moddir/mptcp-route.sh" "/sbin/mptcp-route"
    inst_hook initqueue/online 95 "/sbin/mptcp-route"
    dracut_need_initqueue
}
