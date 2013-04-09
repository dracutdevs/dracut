#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    local _rootdev
    # if cryptsetup is not installed, then we cannot support encrypted devices.
    type -P cryptsetup >/dev/null || return 1

    [[ $hostonly ]] || [[ $mount_needs ]] && {
        for fs in "${host_fs_types[@]}"; do
            [[ $fs = "crypto_LUKS" ]] && return 0
        done
        return 255
    }

    return 0
}

depends() {
    echo dm rootfs-block
    return 0
}

installkernel() {
    instmods dm_crypt =crypto
}

install() {

    check_crypt() {
        local dev=$1 fs=$2

        [[ $fs = "crypto_LUKS" ]] || return 1
        ID_FS_UUID=$(udevadm info --query=property --name=$dev \
            | while read line; do
                [[ ${line#ID_FS_UUID} = $line ]] && continue
                eval "$line"
                echo $ID_FS_UUID
                break
                done)
        [[ ${ID_FS_UUID} ]] || return 1
        if ! [[ $kernel_only ]]; then
            echo " rd.luks.uuid=luks-${ID_FS_UUID} " >> "${initdir}/etc/cmdline.d/90crypt.conf"
        fi
        return 0
    }

    for_each_host_dev_fs check_crypt

    dracut_install cryptsetup rmdir readlink umount
    inst_script "$moddir"/cryptroot-ask.sh /sbin/cryptroot-ask
    inst_script "$moddir"/probe-keydev.sh /sbin/probe-keydev
    inst_hook cmdline 10 "$moddir/parse-keydev.sh"
    inst_hook cmdline 30 "$moddir/parse-crypt.sh"
    if ! dracut_module_included "systemd"; then
        inst_hook cleanup 30 "$moddir/crypt-cleanup.sh"
    fi

    if [[ $hostonly ]]; then
        # filter /etc/crypttab for the devices we need
        while read _mapper _dev _rest; do
            [[ $_mapper = \#* ]] && continue
            [[ $_dev ]] || continue
            for _hdev in "${!host_fs_types[@]}"; do
                [[ ${host_fs_types[$_hdev]} == "crypto_LUKS" ]] || continue
                if [[ $_hdev -ef $_dev ]] || [[ /dev/block/$_hdev -ef $_dev ]]; then
                    echo "$_mapper $_dev $_rest"
                    break
                fi
            done
        done < /etc/crypttab > $initdir/etc/crypttab
    fi

    inst_simple "$moddir/crypt-lib.sh" "/lib/dracut-crypt-lib.sh"

    dracut_install -o \
        $systemdutildir/system-generators/systemd-cryptsetup-generator \
        $systemdutildir/system-generators/systemd-cryptsetup-generator \
        $systemdutildir/systemd-cryptsetup \
        $systemdsystemunitdir/systemd-ask-password-console.path \
        $systemdsystemunitdir/systemd-ask-password-console.service \
        $systemdsystemunitdir/cryptsetup.target \
        $systemdsystemunitdir/sysinit.target.wants/cryptsetup.target \
        systemd-ask-password systemd-tty-ask-password-agent
    inst_script "$moddir"/crypt-run-generator.sh /sbin/crypt-run-generator
    dracut_need_initqueue
}
