#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    test -f /etc/fstab.sys
}

depends() {
    return 0
}

install() {
    dracut_install /etc/fstab.sys
    dracut_install /sbin/fsck*
    type -P e2fsck >/dev/null && dracut_install e2fsck
    inst_hook pre-pivot 00 "$moddir/mount-sys.sh"
}
