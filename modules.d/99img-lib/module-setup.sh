#!/bin/bash
# module-setup for img-lib

# called by dracut
check() {
    for cmd in tar gzip dd; do
        command -v $cmd >/dev/null || return 1
    done
    return 255
}

# called by dracut
depends() {
    return 0
}

# called by dracut
install() {
    inst_multiple tar gzip dd bash
    # TODO: make this conditional on a cmdline flag / config option
    inst_multiple -o cpio xz bzip2
    inst_simple "$moddir/img-lib.sh" "/lib/img-lib.sh"
}

