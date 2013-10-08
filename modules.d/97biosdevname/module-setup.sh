#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

# called by dracut
check() {
    [[ "$mount_needs" ]] && return 1
    type -P biosdevname >/dev/null || return 1
    return 0
}

# called by dracut
depends() {
    return 0
}

# called by dracut
install() {
    inst_multiple biosdevname
    inst_rules 71-biosdevname.rules
}

