#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    local _rootdev
    # if there's no multipath binary, no go.
    type -P multipath >/dev/null || return 1

    is_mpath() {
        local _dev
        _dev=$(get_maj_min $1)
        [ -e /sys/dev/block/$_dev/dm/uuid ] || return 1
        [[ $(cat /sys/dev/block/$_dev/dm/uuid) =~ mpath- ]] && return 0
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
    local _ret
    local _arch=$(uname -m)
    mp_mod_filter() {
        local _funcs='scsi_register_device_handler|dm_dirty_log_type_register|dm_register_path_selector|dm_register_target'
        # subfunctions inherit following FDs
        local _merge=8 _side2=9
        function bmf1() {
            local _f
            while read _f; do
                case "$_f" in
                    *.ko)    [[ $(<         $_f) =~ $_funcs ]] && echo "$_f" ;;
                    *.ko.gz) [[ $(gzip -dc <$_f) =~ $_funcs ]] && echo "$_f" ;;
                    *.ko.xz) [[ $(xz -dc   <$_f) =~ $_funcs ]] && echo "$_f" ;;
                esac
            done
            return 0
        }

        function rotor() {
            local _f1 _f2
            while read _f1; do
                echo "$_f1"
                if read _f2; then
                    echo "$_f2" 1>&${_side2}
                fi
            done | bmf1 1>&${_merge}
            return 0
        }
        # Use two parallel streams to filter alternating modules.
        set +x
        eval "( ( rotor ) ${_side2}>&1 | bmf1 ) ${_merge}>&1"
        [[ $debug ]] && set -x
        return 0
    }

    ( find_kernel_modules_by_path drivers/scsi; if [ "$_arch" = "s390" -o "$_arch" = "s390x" ]; then find_kernel_modules_by_path drivers/s390/scsi; fi;
      find_kernel_modules_by_path drivers/md )  |  mp_mod_filter  |  instmods
}

install() {
    local _f
    dracut_install -o  \
        dmsetup \
        kpartx \
        partx \
        mpath_wait \
        multipath  \
        multipathd \
        xdrgetuid \
        xdrgetprio \
        /etc/xdrdevices.conf \
        /etc/multipath.conf \
        /etc/multipath/*

    inst_libdir_file "libmultipath*" "multipath/*"

    inst_hook pre-trigger 02 "$moddir/multipathd.sh"
    inst_hook cleanup   02 "$moddir/multipathd-stop.sh"
    inst_rules 40-multipath.rules
}

