#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    local _rootdev
    # if we don't have dmraid installed on the host system, no point
    # in trying to support it in the initramfs.
    type -P dmraid >/dev/null || return 1

    [[ $hostonly ]] || [[ $mount_needs ]] && {
        for fs in "${host_fs_types[@]}"; do
            [[ $fs = *_raid_member ]] && return 0
        done
        return 255
    }

    return 0
}

depends() {
    echo dm rootfs-block
    return 0
}

cmdline() {
    local _activated
    declare -A _activated

    for dev in "${!host_fs_types[@]}"; do
        local holder DEVPATH DM_NAME majmin
        [[ "${host_fs_types[$dev]}" != *_raid_member ]] && continue

        majmin=$(get_maj_min $dev)
        DEVPATH=$(
            for i in /sys/block/*; do
                [[ -e "$i/dev" ]] || continue
                if [[ $a == $(<"$i/dev") ]]; then
                    printf "%s" "$i"
                    break
                fi
            done
        )

        for holder in "$DEVPATH"/holders/*; do
            [[ -e "$holder" ]] || continue
            dev="/dev/${holder##*/}"
            DM_NAME="$(dmsetup info -c --noheadings -o name "$dev" 2>/dev/null)"
            [[ ${DM_NAME} ]] && break
        done

        [[ ${DM_NAME} ]] || continue

        if ! [[ ${_activated[${DM_NAME}]} ]]; then
            printf "%s" " rd.dm.uuid=${DM_NAME}"
            _activated["${DM_NAME}"]=1
        fi
    done
}

install() {
    local _i

    cmdline >> "${initdir}/etc/cmdline.d/90dmraid.conf"
    echo >> "${initdir}/etc/cmdline.d/90dmraid.conf"

    inst_multiple dmraid
    inst_multiple -o kpartx
    inst $(command -v partx) /sbin/partx

    inst "$moddir/dmraid.sh" /sbin/dmraid_scan

    inst_rules 64-md-raid.rules

    inst_libdir_file "libdmraid-events*.so*"

    inst_rules "$moddir/61-dmraid-imsm.rules"
    #inst "$moddir/dmraid-cleanup.sh" /sbin/dmraid-cleanup
    inst_hook pre-trigger 30 "$moddir/parse-dm.sh"
}
