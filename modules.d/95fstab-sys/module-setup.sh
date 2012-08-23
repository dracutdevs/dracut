#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    test -f /etc/fstab.sys || [[ -n $add_fstab  ||  -n $fstab_lines ]]
}

depends() {
    echo fs-lib
}

install() {
    [ -f /etc/fstab.sys ] && inst_simple /etc/fstab.sys
    inst_hook pre-pivot 00 "$moddir/mount-sys.sh"
}
