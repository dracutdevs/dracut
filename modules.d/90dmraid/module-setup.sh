#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    local _rootdev
    # if we don't have dmraid installed on the host system, no point
    # in trying to support it in the initramfs.
    type -P dmraid >/dev/null || return 1

    . $dracutfunctions
    [[ $debug ]] && set -x

    check_dmraid() {
        local dev=$1 fs=$2 holder DEVPATH DM_NAME
        [[ "$fs" = "linux_raid_member" ]] && continue
        [[ "$fs" = "${fs%%_raid_member}" ]] && continue

        DEVPATH=$(udevadm info --query=property --name=$dev \
            | while read line; do
                [[ ${line#DEVPATH} = $line ]] && continue
                eval "$line"
                echo $DEVPATH
                break
                done)
        for holder in /sys/$DEVPATH/holders/*; do
            [[ -e $holder ]] || continue
            DM_NAME=$(udevadm info --query=property --path=$holder \
                | while read line; do
                    [[ ${line#DM_NAME} = $line ]] && continue
                    eval "$line"
                    echo $DM_NAME
                    break
                    done)
        done

        [[ ${DM_NAME} ]] || continue
        echo " rd.dm.uuid=${DM_NAME} " >> "${initdir}/etc/cmdline.d/90dmraid.conf"
    }

    [[ $hostonly ]] || [[ $mount_needs ]] && {
        [[ -d "${initdir}/etc/cmdline.d" ]] || mkdir -p "${initdir}/etc/cmdline.d"
        for_each_host_dev_fs check_dmraid
        [ -f "${initdir}/etc/cmdline.d/90dmraid.conf" ] || return 1
    }

    return 0
}

depends() {
    echo dm rootfs-block
    return 0
}

install() {
    local _i
    dracut_install dmraid partx kpartx

    inst "$moddir/dmraid.sh" /sbin/dmraid_scan

    if [ ! -x /lib/udev/vol_id ]; then
        inst_rules 64-md-raid.rules
    fi

    for _i in {"$libdir","$usrlibdir"}/libdmraid-events*.so*; do
        [ -e "$_i" ] && dracut_install "$_i"
    done

    inst_rules "$moddir/61-dmraid-imsm.rules"
    #inst "$moddir/dmraid-cleanup.sh" /sbin/dmraid-cleanup
    inst_hook pre-trigger 30 "$moddir/parse-dm.sh"
}
