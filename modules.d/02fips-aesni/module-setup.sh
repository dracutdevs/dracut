#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

# called by dracut
check() {
    return 255
}

# called by dracut
depends() {
    return 0
}

# called by dracut
installkernel() {
    local _fipsmodules _mod
    _fipsmodules="aesni-intel ghash_clmulni_intel"

    mkdir -m 0755 -p "${initdir}/etc/modprobe.d"

    for _mod in $_fipsmodules; do
        if instmods $_mod; then
            echo $_mod >> "${initdir}/etc/fipsmodules"
            echo "blacklist $_mod" >> "${initdir}/etc/modprobe.d/fips.conf"
        fi
    done
}

# called by dracut
install() {
    return 0
}

