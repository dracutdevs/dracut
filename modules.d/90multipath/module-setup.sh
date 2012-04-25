#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    local _rootdev
    # if there's no multipath binary, no go.
    type -P multipath >/dev/null || return 1

    . $dracutfunctions
    [[ $debug ]] && set -x

    is_mpath() {
        local _dev
        _dev=$(get_maj_min $1)
        [ -e /sys/dev/block/$_dev/dm/uuid ] || return 1
        [[ $(cat /sys/dev/block/$_dev/dm/uuid) =~ ^mpath- ]] && return 0
        return 1
    }

    [[ $hostonly ]] || [[ $mount_needs ]] && {
        for_each_host_dev_fs is_mpath || return 1
    }

    return 0
}

depends() {
    echo rootfs-block
    return 0
}

installkernel() {
    set +x
    mp_mod_filter() {
        local _mpfuncs='scsi_register_device_handler|dm_dirty_log_type_register|dm_register_path_selector|dm_register_target'
        local _f
        while read _f; do case "$_f" in
            *.ko)    [[ $(<         $_f) =~ $_mpfuncs ]] && echo "$_f" ;;
            *.ko.gz) [[ $(gzip -dc <$_f) =~ $_mpfuncs ]] && echo "$_f" ;;
            *.ko.xz) [[ $(xz -dc   <$_f) =~ $_mpfuncs ]] && echo "$_f" ;;
            esac
        done
    }

    ( find_kernel_modules_by_path drivers/scsi; find_kernel_modules_by_path drivers/s390/scsi ;
      find_kernel_modules_by_path drivers/md )  |  mp_mod_filter  |  instmods
    [[ $debug ]] && set -x
}

install() {
    local _f
    for _f in  \
        /sbin/dmsetup \
        /sbin/kpartx \
        /sbin/mpath_wait \
        /sbin/multipath  \
        /sbin/multipathd \
        /sbin/xdrgetuid \
        /sbin/xdrgetprio \
        /etc/xdrdevices.conf \
        /etc/multipath.conf \
        /etc/multipath/*; do
        [ -e "$_f" ] && inst "$_f"
    done

    inst_libdir_file "libmultipath*"
    inst_libdir_file "multipath/*"

    inst_hook pre-trigger 02 "$moddir/multipathd.sh"
    inst_hook cleanup   02 "$moddir/multipathd-stop.sh"
    inst_rules 40-multipath.rules
}

