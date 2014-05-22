#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

# called by dracut
check() {
    # a live host-only image doesn't really make a lot of sense
    [[ $hostonly ]] && return 1
    return 255
}

# called by dracut
depends() {
    return 0
}

# called by dracut
installkernel() {
    instmods overlayfs squashfs
}

# called by dracut
install() {
    inst_multiple umount mount grep
    inst_hook cmdline 30 "$moddir/parse-overlayfs-live.sh"
    inst_hook pre-udev 30 "$moddir/overlayfs-live-genrules.sh"
    inst_script "$moddir/overlayfs-live-root.sh" "/sbin/overlayfs-live-root"
    dracut_need_initqueue
}
