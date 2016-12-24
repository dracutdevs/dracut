#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    # If our prerequisites are not met, fail anyways.
    type -P mount.aufs >/dev/null || return 1

    [[ $hostonly ]] || [[ $mount_needs ]] && {
        for fs in ${host_fs_types[@]}; do
            strstr "$fs" "\|aufs"  && return 0
        done
        return 255
    }

    return 0
}

depends() {
	return 0
}

installkernel() {
	instmods aufs
}

install() {
    dracut_install -o auplink auibusy mount.aufs umount.aufs

    inst_hook cmdline 95 "$moddir/parse-aufsroot.sh"
    inst_hook mount 99 "$moddir/mount-aufs.sh"
    inst "$moddir/aufs-lib.sh" "/lib/aufs-lib.sh"
}
