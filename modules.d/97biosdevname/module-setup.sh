#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    type -P biosdevname >/dev/null || return 1
    return 0
}

depends() {
    return 0
}

install() {
    dracut_install biosdevname
    inst_rules 71-biosdevname.rules
}

