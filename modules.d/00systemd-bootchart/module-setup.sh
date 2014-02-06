#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    [[ "$mount_needs" ]] && return 1
    require_binaries $systemdutildir/systemd-bootchart || return 1
    return 255
}

depends() {
    return 0
}

install() {
    inst_symlink /init /sbin/init
    inst_multiple $systemdutildir/systemd-bootchart
}
