#!/bin/bash

check() {
    return 255
}

depends() {
    echo "bash"
    return 0
}

installkernel() {
    hostonly="" instmods squashfs loop
}

install() {
    inst_multiple kmod modprobe mount mkdir ln echo
    inst ${moddir}/init.squash.sh /init.squash
}
