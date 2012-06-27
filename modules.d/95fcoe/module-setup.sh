#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    # FIXME
    # If hostonly was requested, fail the check until we have some way of
    # knowing we are booting from FCoE
    [[ $hostonly ]] || [[ $mount_needs ]] && return 1

    for i in dcbtool fipvlan lldpad ip readlink; do
        type -P $i >/dev/null || return 1
    done

    return 0
}

depends() {
    echo network rootfs-block
    return 0
}

installkernel() {
    instmods fcoe 8021q edd
}

install() {
    dracut_install ip dcbtool fipvlan lldpad readlink

    mkdir -m 0755 -p "$initdir/var/lib/lldpad"

    inst "$moddir/fcoe-up.sh" "/sbin/fcoe-up"
    inst "$moddir/fcoe-edd.sh" "/sbin/fcoe-edd"
    inst "$moddir/fcoe-genrules.sh" "/sbin/fcoe-genrules.sh"
    inst_hook cmdline 99 "$moddir/parse-fcoe.sh"
}

