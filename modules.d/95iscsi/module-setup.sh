#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    local _rootdev
    # If our prerequisites are not met, fail anyways.
    type -P iscsistart hostname iscsi-iname >/dev/null || return 1

    # If hostonly was requested, fail the check if we are not actually
    # booting from root.

    . $dracutfunctions

    [[ $debug ]] && set -x

    is_iscsi() (
        local _dev
        _dev=$(get_maj_min $1)

        [[ -L /sys/dev/block/$_dev ]] || return
        cd "$(readlink -f /sys/dev/block/$_dev)"
        until [[ -d sys || -d iscsi_session ]]; do
            cd ..
        done
        [[ -d iscsi_session ]]
    )

    [[ $hostonly ]] || [[ $mount_needs ]] && {
        for_each_host_dev_fs is_iscsi || return 1
    }
    return 0
}

depends() {
    echo network rootfs-block
}

installkernel() {
    instmods iscsi_tcp iscsi_ibft crc32c bnx2i iscsi_boot_sysfs qla4xxx cxgb3i cxgb4i be2iscsi
    iscsi_module_filter() {
        local _iscsifuncs='iscsi_register_transport'
        local _f
        while read _f; do case "$_f" in
            *.ko)    [[ $(<         $_f) =~ $_iscsifuncs ]] && echo "$_f" ;;
            *.ko.gz) [[ $(gzip -dc <$_f) =~ $_iscsifuncs ]] && echo "$_f" ;;
            *.ko.xz) [[ $(xz -dc   <$_f) =~ $_iscsifuncs ]] && echo "$_f" ;;
            esac
        done
    }
    { find_kernel_modules_by_path drivers/scsi; find_kernel_modules_by_path drivers/s390/scsi; } \
    | iscsi_module_filter  |  instmods
}

install() {
    dracut_install umount
    dracut_install -o iscsiuio
    inst iscsistart
    inst hostname
    inst iscsi-iname
    inst_hook cmdline 90 "$moddir/parse-iscsiroot.sh"
    inst_hook cleanup 90 "$moddir/cleanup-iscsi.sh"
    inst "$moddir/iscsiroot.sh" "/sbin/iscsiroot"
    inst "$moddir/mount-lun.sh" "/bin/mount-lun.sh"
}
