#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

# called by dracut
check() {
    return 255
}

# called by dracut
depends() {
    echo masterkey
    return 0
}

# called by dracut
installkernel() {
    instmods ecryptfs
}

# called by dracut
install() {
    inst_hook pre-pivot 63 "$moddir/ecryptfs-mount.sh"
}
