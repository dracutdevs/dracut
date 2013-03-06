#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
        rootopts="defaults"
        while read dev mp fs opts dump fsck; do
            # skip comments
            [ "${dev%%#*}" != "$dev" ] && continue

            if [ "$mp" = "/" ]; then
                # sanity - determine/fix fstype
                rootfs=$(find_mp_fstype /)
                rootfs=${rootfs:-$fs}
                rootopts=$opts
                break
            fi
        done < /etc/fstab

        [ "$rootfs" = "reiserfs" ] && journaldev=$(fs_get_option $rootopts "jdev")
        [ "$rootfs" = "xfs" ] && journaldev=$(fs_get_option $rootopts "logdev")
        if [ -n "$journaldev" ]; then
            echo "root.journaldev=$journaldev" >> "${initdir}/etc/cmdline.d/95root-jurnaldev.conf"
        fi
    return 0
}

depends() {
    echo fs-lib
}

install() {
    dracut_install umount
    if ! dracut_module_included "systemd"; then
        inst_hook cmdline 95 "$moddir/parse-block.sh"
        inst_hook pre-udev 30 "$moddir/block-genrules.sh"
        inst_hook mount 99 "$moddir/mount-root.sh"
    fi
}

