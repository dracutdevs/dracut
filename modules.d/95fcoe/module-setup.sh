#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

# called by dracut
check() {
    for i in dcbtool fipvlan lldpad ip readlink; do
        type -P $i >/dev/null || return 1
    done

    return 0
}

# called by dracut
depends() {
    echo network rootfs-block
    return 0
}

# called by dracut
installkernel() {
    instmods fcoe 8021q edd
}

# called by dracut
install() {
    inst_multiple ip dcbtool fipvlan lldpad readlink

    mkdir -m 0755 -p "$initdir/var/lib/lldpad"

    inst "$moddir/fcoe-up.sh" "/sbin/fcoe-up"
    inst "$moddir/fcoe-edd.sh" "/sbin/fcoe-edd"
    inst "$moddir/fcoe-genrules.sh" "/sbin/fcoe-genrules.sh"
    inst_hook cmdline 99 "$moddir/parse-fcoe.sh"
    dracut_need_initqueue
}

