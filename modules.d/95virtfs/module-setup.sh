#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    [[ $hostonly ]] || [[ $mount_needs ]] && {
        for fs in ${host_fs_types[@]}; do
            strstr "$fs" "\|9p" && return 0
        done
        return 1
    }

    return 0
}

depends() {
    return 0
}

installkernel() {
    instmods 9p 9pnet_virtio
}

install() {
    inst_hook cmdline 95 "$moddir/parse-virtfs.sh"
    inst_hook mount 99 "$moddir/mount-virtfs.sh"
}
