#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

# called by dracut
check() {
    local _arch=$(uname -m)
    [ -x /sbin/dasd_configure ] || return 1
    [ "$_arch" = "s390" -o "$_arch" = "s390x" ] || return 1
    return 0
}

# called by dracut
depends() {
    echo 'dasd_mod'
    return 0
}

# called by dracut
install() {
    inst_multiple /usr/lib/udev/collect
    inst_hook cmdline 30 "$moddir/parse-dasd.sh"
    if [[ $hostonly ]] ; then
        inst_rules_wildcard 51-dasd-*.rules
    fi
    inst_rules 59-dasd.rules
}
