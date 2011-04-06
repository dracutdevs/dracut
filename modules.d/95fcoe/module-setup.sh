#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    # FIXME
    # If hostonly was requested, fail the check until we have some way of
    # knowing we are booting from FCoE
    [[ $hostonly ]] && return 1

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
    dracut_install ip 
    inst dcbtool 
    inst fipvlan
    inst lldpad

    mkdir -m 0755 -p "$initdir/var/lib/lldpad"

    inst "$moddir/fcoe-up" "/sbin/fcoe-up"
    inst "$moddir/fcoe-genrules.sh" "/sbin/fcoe-genrules.sh"
    inst_hook pre-udev 60 "$moddir/fcoe-genrules.sh"
    inst_hook cmdline 99 "$moddir/parse-fcoe.sh"
}

