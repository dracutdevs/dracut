#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

# called by dracut
check() {
    [[ -d /etc/sysconfig/network-scripts ]] && return 0
    return 255
}

# called by dracut
depends() {
    echo "network"
    return 0
}

# called by dracut
install() {
    inst_hook pre-pivot 85 "$moddir/write-ifcfg.sh"
}

