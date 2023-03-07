#!/bin/bash

check() {
    require_kernel_modules overlay || return 1
    return 255
}

depends() {
    echo base
}

installkernel() {
    hostonly="" instmods overlay
}

install() {
    inst_hook mount 01 "$moddir/mount-overlayfs.sh"
    inst_hook pre-mount 01 "$moddir/prepare-overlayfs.sh"
}
