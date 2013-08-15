#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    # No point trying to support lvm if the binaries are missing
    type -P lvm >/dev/null || return 1

    [[ $hostonly ]] || [[ $mount_needs ]] && {
        for fs in "${host_fs_types[@]}"; do
            [[ $fs = LVM*_member ]] && return 0
        done
        return 255
    }

    return 0
}

depends() {
    # We depend on dm_mod being loaded
    echo rootfs-block dm
    return 0
}

get_host_lvs() {
    local _activated
    declare -A _activated

    for dev in "${!host_fs_types[@]}"; do
        [ -e /sys/block/${dev#/dev/}/dm/name ] || continue
        [ -e /sys/block/${dev#/dev/}/dm/uuid ] || continue
        uuid=$(</sys/block/${dev#/dev/}/dm/uuid)
        [[ "${uuid#LVM-}" == "$uuid" ]] && continue
        dev=$(</sys/block/${dev#/dev/}/dm/name)
        eval $(dmsetup splitname --nameprefixes --noheadings --rows "$dev" 2>/dev/null)
        [[ ${DM_VG_NAME} ]] && [[ ${DM_LV_NAME} ]] || return 1
        if ! [[ ${_activated[${DM_VG_NAME}/${DM_LV_NAME}]} ]]; then
            printf "%s\n" "${DM_VG_NAME}/${DM_LV_NAME} "
            _activated["${DM_VG_NAME}/${DM_LV_NAME}"]=1
        fi
    done
}

cmdline() {
    get_host_lvs | while read line; do
        printf " rd.lvm.lv=$line"
    done
}

install() {
    local _i _needthin

    inst lvm

    get_host_lvs | while read line; do
        printf "%s" " rd.lvm.lv=$line"
        if ! [[ $_needthin ]]; then
            [[ "$(lvs --noheadings -o segtype ${line%%/*} 2>/dev/null)" == *thin* ]] && _needthin=1
        fi
    done >> "${initdir}/etc/cmdline.d/90lvm.conf"

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

    if ! [[ -e ${initdir}/etc/lvm/lvm.conf ]]; then
        mkdir -p "${initdir}/etc/lvm"
        {
            echo 'global {'
            echo 'locking_type = 4'
            echo 'use_lvmetad = 0'
            echo '}'
        } > "${initdir}/etc/lvm/lvm.conf"
    fi

    inst_rules 11-dm-lvm.rules
    # Gentoo ebuild for LVM2 prior to 2.02.63-r1 doesn't install above rules
    # files, but provides the one below:
    inst_rules 64-device-mapper.rules
    # debian udev rules
    inst_rules 56-lvm.rules 60-persistent-storage-lvm.rules

    inst_script "$moddir/lvm_scan.sh" /sbin/lvm_scan
    inst_hook cmdline 30 "$moddir/parse-lvm.sh"

    inst_libdir_file "libdevmapper-event-lvm*.so"

    if [[ $_needthin ]]; then
        inst_multiple -o thin_dump thin_restore thin_check thin_repair
    fi

}

