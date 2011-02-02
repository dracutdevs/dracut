#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    # No Xen-detect? Boo!!
    if ! hash xen-detect 2>/dev/null; then
        [[ -d /usr/lib/xen-default ]] && \
            hash -p /usr/lib/xen-default/bin/xen-detect xen-detect || return 1
    fi

    . $dracutfunctions
    [[ $debug ]] && set -x

    # Yes, we are under Xen PV env.
    xen-detect | grep -q -v PV || return 0

    return 1
}

depends() {
    return 0
}

installkernel() {
    for i in \
        xenbus_probe_frontend xen-pcifront \
        xen-fbfront xen-kbdfront xen-blkfront xen-netfront \
        ; do
        modinfo -k $kernel $i >/dev/null 2>&1 && instmods $i
    done

}

install() {
    hash xen-detect 2>/dev/null || \
        hash -p /usr/lib/xen-default/bin/xen-detect xen-detect
    inst "$(hash -t xen-detect)" /sbin/xen-detect
    inst_hook pre-udev 40 "$moddir/xen-pre-udev.sh"
}

