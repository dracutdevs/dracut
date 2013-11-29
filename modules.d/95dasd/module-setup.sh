#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

# called by dracut
check() {
    local _arch=$(uname -m)
    [ -x /sbin/normalize_dasd_arg ] || return 1
    [ "$_arch" = "s390" -o "$_arch" = "s390x" ] || return 1
    return 0
}

# called by dracut
depends() {
    echo "dasd_mod"
    return 0
}

# called by dracut
install() {
    inst_hook cmdline 30 "$moddir/parse-dasd.sh"
    inst_multiple dasdinfo dasdconf.sh normalize_dasd_arg
    if [[ $hostonly ]]; then
        inst /etc/dasd.conf
    fi
    inst_rules 56-dasd.rules
    inst_rules 59-dasd.rules
}

