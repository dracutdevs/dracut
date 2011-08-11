#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    return 255
}

depends() {
    echo masterkey
    return 0
}

installkernel() {
    instmods ecryptfs
}

install() {
    inst_hook pre-pivot 63 "$moddir/ecryptfs-mount.sh"
}
