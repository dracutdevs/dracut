#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    # a live host-only image doesn't really make a lot of sense
    [[ $hostonly ]] && return 1
    return 255
}

depends() {
    # if dmsetup is not installed, then we cannot support fedora/red hat
    # style live images
    echo dm rootfs-block
    return 0
}

installkernel() {
    instmods squashfs
}

install() {
    dracut_install umount
    inst dmsetup
    inst blkid
    inst dd
    inst losetup
    inst grep

    dracut_install -o eject

    inst blockdev
    type -P checkisomd5 >/dev/null && inst checkisomd5
    inst_hook cmdline 30 "$moddir/parse-dmsquash-live.sh"
    inst_hook pre-udev 30 "$moddir/dmsquash-live-genrules.sh"
    inst_hook pre-udev 30 "$moddir/dmsquash-liveiso-genrules.sh"
    inst_hook pre-pivot 20 "$moddir/apply-live-updates.sh"
    inst "$moddir/dmsquash-live-root" "/sbin/dmsquash-live-root"
    # should probably just be generally included
    inst_rules 60-cdrom_id.rules
}

