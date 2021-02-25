#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

# called by dracut
check() {
    local _arch=${DRACUT_ARCH:-$(uname -m)}
    [[ $_arch == "s390" ]] || [[ $_arch == "s390x" ]] || return 1
    return 0
}

# called by dracut
installkernel() {
    if [[ $hostonly ]]; then
        for dev in /sys/devices/dcssblk/*/block/dcssblk*; do
            [[ -e $dev ]] || continue
            hostonly='' instmods dcssblk
            return $?
        done
    else
        hostonly='' instmods dcssblk
    fi
}

# called by dracut
install() {
    inst_hook cmdline 30 "$moddir/parse-dcssblk.sh"
    # If there is a config file which contains avail (best only of root device)
    # disks to activate add it and use it during boot -> then we do not need
    # a kernel param anymore
    #if [[ $hostonly ]]; then
    #    inst /etc/dcssblk.conf
    #fi
}
