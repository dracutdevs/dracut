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
    echo fcoe uefi-lib
    return 0
}

# called by dracut
install() {
    inst_hook cmdline 20 "$moddir/parse-uefifcoe.sh"
}
