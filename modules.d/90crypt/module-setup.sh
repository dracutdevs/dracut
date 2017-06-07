#!/usr/bin/env bash

# called by dracut
check() {
    local _rootdev
    # if cryptsetup is not installed, then we cannot support encrypted devices.
    require_any_binary $systemdutildir/systemd-cryptsetup cryptsetup || return 1

    [[ $hostonly ]] || [[ $mount_needs ]] && {
        for fs in "${host_fs_types[@]}"; do
            [[ $fs = "crypto_LUKS" ]] && return 0
        done
        return 255
    }

    return 0
}

# called by dracut
depends() {
    echo dm rootfs-block
    return 0
}

# called by dracut
installkernel() {
    hostonly="" instmods drbg
    arch=$(arch)
    [[ $arch == x86_64 ]] && arch=x86
    instmods dm_crypt =crypto =drivers/crypto =arch/$arch/crypto
}

# called by dracut
cmdline() {
    local dev UUID
    for dev in "${!host_fs_types[@]}"; do
        [[ "${host_fs_types[$dev]}" != "crypto_LUKS" ]] && continue

        UUID=$(
            blkid -u crypto -o export $dev \
                | while read line || [ -n "$line" ]; do
                [[ ${line#UUID} = $line ]] && continue
                printf "%s" "${line#UUID=}"
                break
            done
        )
        [[ ${UUID} ]] || continue
        printf "%s" " rd.luks.uuid=luks-${UUID}"
    done
}

# called by dracut
install() {

    if [[ $hostonly_cmdline == "yes" ]]; then
        local _cryptconf=$(cmdline)
        [[ $_cryptconf ]] && printf "%s\n" "$_cryptconf" >> "${initdir}/etc/cmdline.d/90crypt.conf"
    fi

    inst_hook cmdline 30 "$moddir/parse-crypt.sh"
    if ! dracut_module_included "systemd"; then
        inst_multiple cryptsetup rmdir readlink umount
        inst_script "$moddir"/cryptroot-ask.sh /sbin/cryptroot-ask
        inst_script "$moddir"/probe-keydev.sh /sbin/probe-keydev
        inst_hook cmdline 10 "$moddir/parse-keydev.sh"
        inst_hook cleanup 30 "$moddir/crypt-cleanup.sh"
    fi

    if [[ $hostonly ]] && [[ -f /etc/crypttab ]]; then
        # filter /etc/crypttab for the devices we need
        while read _mapper _dev _rest || [ -n "$_mapper" ]; do
            [[ $_mapper = \#* ]] && continue
            [[ $_dev ]] || continue

            [[ $_dev == UUID=* ]] && \
                _dev="/dev/disk/by-uuid/${_dev#UUID=}"

            for _hdev in "${!host_fs_types[@]}"; do
                [[ ${host_fs_types[$_hdev]} == "crypto_LUKS" ]] || continue
                if [[ $_hdev -ef $_dev ]] || [[ /dev/block/$_hdev -ef $_dev ]]; then
                    echo "$_mapper $_dev $_rest"
                    break
                fi
            done
        done < /etc/crypttab > $initdir/etc/crypttab
        mark_hostonly /etc/crypttab
    fi

    inst_simple "$moddir/crypt-lib.sh" "/lib/dracut-crypt-lib.sh"

    if dracut_module_included "systemd"; then
        inst_multiple -o \
                      $systemdutildir/system-generators/systemd-cryptsetup-generator \
                      $systemdutildir/systemd-cryptsetup \
                      $systemdsystemunitdir/systemd-ask-password-console.path \
                      $systemdsystemunitdir/systemd-ask-password-console.service \
                      $systemdsystemunitdir/cryptsetup.target \
                      $systemdsystemunitdir/sysinit.target.wants/cryptsetup.target \
                      systemd-ask-password systemd-tty-ask-password-agent
        inst_script "$moddir"/crypt-run-generator.sh /sbin/crypt-run-generator
    fi

    dracut_need_initqueue
}
