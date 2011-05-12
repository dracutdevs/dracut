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
        [ -e /sys/dev/block/$1/dm/uuid ] || return 1
        [[ $(cat /sys/dev/block/$1/dm/uuid) =~ ^mpath- ]] && return 0
        return 1
    }

    if [[ $hostonly ]]; then
        _rootdev=$(find_root_block_device)
        if [[ $_rootdev ]]; then
            check_block_and_slaves is_mpath "$_rootdev" && return 0
        fi
        return 1
    fi

    return 0
}

depends() {
    echo rootfs-block
    return 0
}

installkernel() {
    mp_mod_test() {
        local mpfuncs='scsi_register_device_handler|dm_dirty_log_type_register|dm_register_path_selector|dm_register_target'
        egrep -q "$mpfuncs" "$1"
    }

    instmods $(filter_kernel_modules mp_mod_test)
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
        /etc/multipath/* \
        "$libdir"/libmultipath* "$libdir"/multipath/*; do
        [ -e "$_f" ] && inst "$_f"
    done

    inst_hook pre-trigger 02 "$moddir/multipathd.sh"
    inst_hook pre-pivot   02 "$moddir/multipathd-stop.sh"
    inst_rules 40-multipath.rules
}

