#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    local _fcoe_ctlr
    [[ $hostonly ]] || [[ $mount_needs ]] && {
        for c in /sys/bus/fcoe/devices/ctlr_* ; do
            [ -L $c ] || continue
            _fcoe_ctlr=$c
        done
        [ -z "$_fcoe_ctlr" ] && return 255
    }

    require_binaries dcbtool fipvlan lldpad ip readlink fcoemon fcoeadm || return 1
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
    inst_multiple ip dcbtool fipvlan lldpad readlink lldptool fcoemon fcoeadm
    inst_libdir_file 'libhbalinux.so*'
    inst "/etc/hba.conf" "/etc/hba.conf"

    mkdir -m 0755 -p "$initdir/var/lib/lldpad"
    mkdir -m 0755 -p "$initdir/etc/fcoe"

    inst "$moddir/fcoe-up.sh" "/sbin/fcoe-up"
    inst "$moddir/fcoe-edd.sh" "/sbin/fcoe-edd"
    inst "$moddir/fcoe-genrules.sh" "/sbin/fcoe-genrules.sh"
    inst_hook pre-trigger 03 "$moddir/lldpad.sh"
    inst_hook cmdline 99 "$moddir/parse-fcoe.sh"
    inst_hook cleanup 90 "$moddir/cleanup-fcoe.sh"
    dracut_need_initqueue
}

