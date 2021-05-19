#!/bin/bash
# This file is part of dracut.
# SPDX-License-Identifier: GPL-2.0-or-later

# Prerequisite check(s) for module.
check() {

    [[ $hostonly ]] || [[ $mount_needs ]] && {
        for fs in "${host_fs_types[@]}"; do
            [[ $fs == LVM*_member ]] && return 0
        done
        return 255
    }

    # If the binary(s) requirements are not fulfilled the module can't be installed.
    require_binaries \
        lvm \
        "$udevdir"/pvscan-udev-initrd.sh \
        || return 1

    # Return 0 to include the module.
    return 0

}

# Module dependency requirements.
depends() {

    # This module has external dependency on other module(s).
    echo rootfs-block dm systemd-udevd
    # Return 0 to include the dependent module(s) in the initramfs.
    return 0

}

# Commandline.
cmdline() {
    local _activated
    declare -A _activated

    for dev in "${!host_fs_types[@]}"; do
        [ -e /sys/block/"${dev#/dev/}"/dm/name ] || continue
        [ -e /sys/block/"${dev#/dev/}"/dm/uuid ] || continue
        uuid=$(< /sys/block/"${dev#/dev/}"/dm/uuid)
        [[ ${uuid#LVM-} == "$uuid" ]] && continue
        dev=$(< /sys/block/"${dev#/dev/}"/dm/name)
        eval "$(dmsetup splitname --nameprefixes --noheadings --rows "$dev" 2> /dev/null)"
        [[ ${DM_VG_NAME} ]] && [[ ${DM_LV_NAME} ]] || return 1
        if ! [[ ${_activated[DM_VG_NAME / DM_LV_NAME]} ]]; then
            printf " rd.lvm.lv=%s " "${DM_VG_NAME}/${DM_LV_NAME} "
            _activated["${DM_VG_NAME}/${DM_LV_NAME}"]=1
        fi
    done
}

# Install kernel module(s).
installkernel() {
    hostonly='' instmods dm-snapshot
}

# Install the required file(s) and directories for the module in the initramfs.
install() {

    if [[ $hostonly_cmdline == "yes" ]]; then
        # shellcheck disable=SC2155
        local _lvmconf=$(cmdline)
        [[ $_lvmconf ]] && printf "%s\n" "$_lvmconf" >> "${initdir}/etc/cmdline.d/90lvm.conf"
    fi

    inst_script "$moddir/pvscan-udev-initrd.sh" "$udevdir"/pvscan-udev-initrd.sh

    inst_rules "$moddir/64-lvm-systemd.rules"

    inst_hook cmdline 30 "$moddir/parse-lvm.sh"

    inst_multiple -o \
        "$udevrulesdir"/11-dm-lvm.rules \
        cache_dump cache_restore cache_check cache_repair \
        era_check era_dump era_invalidate era_restore lvm \
        thin_dump thin_restore thin_check thin_repair

    # Install required libraries.
    _arch=${DRACUT_ARCH:-$(uname -m)}
    inst_libdir_file {"tls/$_arch/",tls/,"$_arch/",}"libdevmapper-event-lvm*.so"

    # Install the hosts local user configurations if enabled.
    if [[ $hostonly ]]; then
        inst_multiple -H -o \
            /etc/lvm/lvm.conf \
            /etc/lvm/lvmlocal.conf
    fi

    eval "$(lvm dumpconfig global/system_id_source &> /dev/null)"
    if [ "$system_id_source" == "file" ]; then
        eval "$(lvm dumpconfig global/system_id_file)"
        if [ -f "$system_id_file" ]; then
            inst_simple -H "$system_id_file"
        fi
    fi
}
