#!/bin/bash
# module-setup for img-lib

check() {
    require_binaries tar gzip dd bash || return 1
    return 255
}

depends() {
    return 0
}

install() {
    inst_multiple tar gzip dd bash
    # TODO: make this conditional on a cmdline flag / config option
    inst_multiple -o cpio xz bzip2
    inst_simple "$moddir/img-lib.sh" "/lib/img-lib.sh"
}

