#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    local _rootdev _activated
    # No point trying to support lvm if the binaries are missing
    type -P lvm >/dev/null || return 1

    check_lvm() {
        local DM_VG_NAME DM_LV_NAME DM_UDEV_DISABLE_DISK_RULES_FLAG
        eval $(udevadm info --query=property --name=/dev/block/$1|egrep '(DM_VG_NAME|DM_LV_NAME|DM_UDEV_DISABLE_DISK_RULES_FLAG)=')
        [[ "$DM_UDEV_DISABLE_DISK_RULES_FLAG" = "1" ]] && return 1
        [[ ${DM_VG_NAME} ]] && [[ ${DM_LV_NAME} ]] || return 1
        if ! strstr " ${_activated[*]} " " ${DM_VG_NAME}/${DM_LV_NAME} "; then
            if ! [[ $kernel_only ]]; then
                echo " rd.lvm.lv=${DM_VG_NAME}/${DM_LV_NAME} " >> "${initdir}/etc/cmdline.d/90lvm.conf"
            fi
            push _activated "${DM_VG_NAME}/${DM_LV_NAME}"
        fi
        return 0
    }

    [[ $hostonly ]] || [[ $mount_needs ]] && {
        for_each_host_dev_and_slaves check_lvm || return 1
    }

    return 0
}

depends() {
    # We depend on dm_mod being loaded
    echo rootfs-block dm
    return 0
}

install() {
    local _i
    inst lvm

    inst_rules "$moddir/64-lvm.rules"

    if [[ $hostonly ]] || [[ $lvmconf = "yes" ]]; then
        if [ -f /etc/lvm/lvm.conf ]; then
            inst_simple /etc/lvm/lvm.conf
            # FIXME: near-term hack to establish read-only locking;
            # use command-line lvm.conf editor once it is available
            sed -i -e 's/\(^[[:space:]]*\)locking_type[[:space:]]*=[[:space:]]*[[:digit:]]/\1locking_type = 4/' ${initdir}/etc/lvm/lvm.conf
            sed -i -e 's/\(^[[:space:]]*\)use_lvmetad[[:space:]]*=[[:space:]]*[[:digit:]]/\1use_lvmetad = 0/' ${initdir}/etc/lvm/lvm.conf
        fi
    fi

    inst_rules 11-dm-lvm.rules
    # Gentoo ebuild for LVM2 prior to 2.02.63-r1 doesn't install above rules
    # files, but provides the one below:
    inst_rules 64-device-mapper.rules

    inst_script "$moddir/lvm_scan.sh" /sbin/lvm_scan
    inst_hook cmdline 30 "$moddir/parse-lvm.sh"

    inst_libdir_file "libdevmapper-event-lvm*.so"
}

