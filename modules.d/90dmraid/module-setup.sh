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

install() {
    local _i

    check_dmraid() {
        local dev=$1 fs=$2 holder DEVPATH DM_NAME majmin
        [[ "$fs" != *_raid_member ]] && return 1


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
            DM_NAME="$(/usr/sbin/dmsetup info -c --noheadings -o name "$dev" 2>/dev/null)"
            [[ ${DM_NAME} ]] && break
        done

        [[ ${DM_NAME} ]] || return 1
        if ! [[ $kernel_only ]]; then
            echo " rd.dm.uuid=${DM_NAME} " >> "${initdir}/etc/cmdline.d/90dmraid.conf"
        fi
        return 0
    }

    for_each_host_dev_fs check_dmraid

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
