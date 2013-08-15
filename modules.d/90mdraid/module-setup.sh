#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    local _rootdev
    # No mdadm?  No mdraid support.
    type -P mdadm >/dev/null || return 1

    [[ $hostonly ]] || [[ $mount_needs ]] && {
        for fs in "${host_fs_types[@]}"; do
            [[ "$fs" == *_raid_member ]] && return 0
        done
        return 255
    }

    return 0
}

depends() {
    echo rootfs-block
    return 0
}

installkernel() {
    instmods =drivers/md
}

cmdline() {
    local _activated dev line UUID
    declare -A _activated

    for dev in "${!host_fs_types[@]}"; do
        [[ "${host_fs_types[$dev]}" != *_raid_member ]] && continue

        UUID=$(
            /sbin/mdadm --examine --export $dev \
                | while read line; do
                [[ ${line#MD_UUID=} = $line ]] && continue
                printf "%s" "${line#MD_UUID=} "
            done
        )

        if ! [[ ${_activated[${UUID}]} ]]; then
            printf "%s" " rd.md.uuid=${UUID}"
            _activated["${UUID}"]=1
        fi

    done
}

install() {
    inst_multiple cat
    inst_multiple -o mdmon
    inst $(command -v partx) /sbin/partx
    inst $(command -v mdadm) /sbin/mdadm

    cmdline  >> "${initdir}/etc/cmdline.d/90mdraid.conf"

    inst_rules 64-md-raid.rules
    # remove incremental assembly from stock rules, so they don't shadow
    # 65-md-inc*.rules and its fine-grained controls, or cause other problems
    # when we explicitly don't want certain components to be incrementally
    # assembled
    sed -i -r -e '/RUN\+?="[[:alpha:]/]*mdadm[[:blank:]]+(--incremental|-I)[[:blank:]]+(\$env\{DEVNAME\}|\$tempnode)"/d' "${initdir}${udevdir}/rules.d/64-md-raid.rules"

    inst_rules "$moddir/65-md-incremental-imsm.rules"

    inst_rules "$moddir/59-persistent-storage-md.rules"
    prepare_udev_rules 59-persistent-storage-md.rules

    # guard against pre-3.0 mdadm versions, that can't handle containers
    if ! mdadm -Q -e imsm /dev/null >/dev/null 2>&1; then
        inst_hook pre-trigger 30 "$moddir/md-noimsm.sh"
    fi
    if ! mdadm -Q -e ddf /dev/null >/dev/null 2>&1; then
        inst_hook pre-trigger 30 "$moddir/md-noddf.sh"
    fi

    if [[ $hostonly ]] || [[ $mdadmconf = "yes" ]]; then
        if [ -f /etc/mdadm.conf ]; then
            inst /etc/mdadm.conf
        else
            [ -f /etc/mdadm/mdadm.conf ] && inst /etc/mdadm/mdadm.conf /etc/mdadm.conf
        fi
    fi

    inst_hook pre-udev 30 "$moddir/mdmon-pre-udev.sh"
    inst_hook pre-trigger 30 "$moddir/parse-md.sh"
    inst_hook pre-mount 10 "$moddir/mdraid-waitclean.sh"
    inst_hook cleanup 99 "$moddir/mdraid-needshutdown.sh"
    inst_hook shutdown 30 "$moddir/md-shutdown.sh"
    inst_script "$moddir/mdraid-cleanup.sh" /sbin/mdraid-cleanup
    inst_script "$moddir/mdraid_start.sh" /sbin/mdraid_start
    if dracut_module_included "systemd"; then
        if [ -e $systemdsystemunitdir/mdmon@.service ]; then
            inst_simple $systemdsystemunitdir/mdmon@.service
        fi
    fi
    inst_hook pre-shutdown 30 "$moddir/mdmon-pre-shutdown.sh"
}
