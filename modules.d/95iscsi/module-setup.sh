#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

# called by dracut
check() {
    local _rootdev
    # If our prerequisites are not met, fail anyways.
    require_binaries iscsistart hostname iscsi-iname || return 1

    # If hostonly was requested, fail the check if we are not actually
    # booting from root.

    is_iscsi() {
        local _dev=$1

        [[ -L "/sys/dev/block/$_dev" ]] || return
        cd "$(readlink -f "/sys/dev/block/$_dev")"
        until [[ -d sys || -d iscsi_session ]]; do
            cd ..
        done
        [[ -d iscsi_session ]]
    }

    [[ $hostonly ]] || [[ $mount_needs ]] && {
        pushd . >/dev/null
        for_each_host_dev_and_slaves is_iscsi || return 255
        popd >/dev/null
    }
    return 0
}

# called by dracut
depends() {
    echo network rootfs-block
}

# called by dracut
installkernel() {
    local _arch=$(uname -m)

    instmods bnx2i qla4xxx cxgb3i cxgb4i be2iscsi
    hostonly="" instmods iscsi_tcp iscsi_ibft crc32c iscsi_boot_sysfs
    iscsi_module_filter() {
        local _funcs='iscsi_register_transport'
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

    { find_kernel_modules_by_path drivers/scsi; if [ "$_arch" = "s390" -o "$_arch" = "s390x" ]; then find_kernel_modules_by_path drivers/s390/scsi; fi;} \
    | iscsi_module_filter  |  instmods
}

# called by dracut
install() {
    inst_multiple umount iscsistart hostname iscsi-iname
    inst_multiple -o iscsiuio
    inst_hook cmdline 90 "$moddir/parse-iscsiroot.sh"
    inst_hook cleanup 90 "$moddir/cleanup-iscsi.sh"
    inst "$moddir/iscsiroot.sh" "/sbin/iscsiroot"
    if ! dracut_module_included "systemd"; then
        inst "$moddir/mount-lun.sh" "/bin/mount-lun.sh"
    fi
    dracut_need_initqueue
}
