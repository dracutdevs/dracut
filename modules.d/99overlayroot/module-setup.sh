#!/bin/bash

check() {
    require_binaries "chmod mount mkdir"
    if [ ! $(cmd /proc/filesystems|grep overlay|cut -f2) ]; then 
        echo "Overlay filesystem support is not available on this kernel."
        echo "Overlayroot not installed."
        return 1
    fi
    return 0
}

installkernel() {
    instmods overlay
}

install () {
    inst_hook pre-pivot 50 "$moddir"/overlaymount.sh
}
