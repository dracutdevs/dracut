#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    # a live host-only image doesn't really make a lot of sense
    [[ $hostonly ]] && return 1
    return 0
}

depends() {
    # if dmsetup is not installed, then we cannot support fedora/red hat 
    # style live images
    echo dm rootfs-block
    return 0
}

install() {
    dracut_install umount
    inst dmsetup
    inst blkid
    inst dd
    inst losetup
    inst grep

    # eject might be a symlink to consolehelper
    if [ -L /usr/bin/eject ]; then
        dracut_install /usr/sbin/eject
    else
        inst eject
    fi

    inst blockdev
    type -P checkisomd5 >/dev/null && inst checkisomd5
    inst_hook cmdline 30 "$moddir/parse-dmsquash-live.sh"
    inst_hook pre-udev 30 "$moddir/dmsquash-live-genrules.sh"
    inst_hook pre-udev 30 "$moddir/dmsquash-liveiso-genrules.sh"
    inst "$moddir/dmsquash-live-root" "/sbin/dmsquash-live-root"
    # should probably just be generally included
    inst_rules 60-cdrom_id.rules
}

