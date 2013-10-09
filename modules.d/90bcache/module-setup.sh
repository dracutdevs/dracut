#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    if ! blkid -k | { while read line; do [[ $line == bcache ]] && exit 0; done; exit 1; } \
        && ! type -P probe-bcache >/dev/null; then
        return 1
    fi

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
    blkid -k | { while read line; do [[ $line == bcache ]] && exit 0; done; exit 1; } || inst_multiple -o probe-bcache
    inst_multiple -o ${udevdir}/bcache-register
    inst_rules 61-bcache.rules 69-bcache.rules
}
