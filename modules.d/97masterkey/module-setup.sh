#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

# called by dracut
check() {
    [[ $hostonly ]] && {
        require_binaries keyctl uname || return 1
    }

    return 255
}

# called by dracut
depends() {
    return 0
}

# called by dracut
installkernel() {
    instmods trusted encrypted
}

# called by dracut
install() {
    inst_multiple keyctl uname
    inst_hook pre-pivot 60 "$moddir/masterkey.sh"
}
