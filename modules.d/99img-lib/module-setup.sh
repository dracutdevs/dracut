#!/bin/bash
# module-setup for img-lib

check() {
    for cmd in tar gzip dd; do
        command -v $cmd >/dev/null || return 1
    done
    return 255
}

depends() {
    return 0
}

install() {
    dracut_install tar gzip dd bash
    # TODO: make this conditional on a cmdline flag / config option
    dracut_install -o cpio xz bzip2
    inst_simple "$moddir/img-lib.sh" "/lib/img-lib.sh"
}

