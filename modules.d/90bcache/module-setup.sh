#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    type -P probe-bcache >/dev/null || return 1

    [[ $hostonly ]] || [[ $mount_needs ]] && {
        for fs in "${host_fs_types[@]}"; do
            [[ $fs = "bcache" ]] && return 0
        done
        return 255
    }

    return 0
}

depends() {
    return 0
}

installkernel() {
    instmods bcache
}

install() {
    dracut_install probe-bcache ${udevdir}/bcache-register
    inst_rules 61-bcache.rules
}

