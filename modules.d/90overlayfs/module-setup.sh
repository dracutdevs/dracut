#!/bin/bash

check() {
    [[ $hostonly ]] && return 1
    return 255
}

depends() {
    echo base
}

installkernel() {
    instmods overlay
}

install() {
    inst_hook mount 01 "$moddir/mount-overlayfs.sh"
    inst_hook pre-mount 01 "$moddir/prepare-overlayfs.sh"
}
