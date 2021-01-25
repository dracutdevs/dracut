#!/bin/sh
# This file is part of dracut.
# SPDX-License-Identifier: GPL-2.0-or-later

# Prerequisite check(s) for module.
check() {
    local _rootdev

    # If the binary(s) requirements are not fulfilled
    # return 1 to not include the binary.
    require_binaries $systemdutildir/systemd-cryptsetup || return 1
    require_binaries $systemdutildir/system-generators/systemd-cryptsetup-generator || return 1

    [[ $hostonly ]] || [[ $mount_needs ]] && {
        for fs in "${host_fs_types[@]}"; do
            [[ $fs = "crypto_LUKS" ]] && return 0
        done
        return 255
     }

    # If the module dependency requirements are not fulfilled
    # return 1 to not include the required module(s).

    if ! dracut_module_included "dm"; then
        derror "systemd-cryptsetup needs dm in the initramfs."
        return 1
    fi

    if ! dracut_module_included "rootfs-block"; then
        derror "systemd-cryptsetup needs rootfs-block in the initramfs."
        return 1
    fi

    if ! dracut_module_included "rootfs-block"; then
        derror "systemd-cryptsetup needs rootfs-block in the initramfs."
        return 1
    fi

    if ! dracut_module_included "systemd"; then
        derror "systemd-cryptsetup needs systemd in the initramfs."
        return 1
    fi

    if ! dracut_module_included "systemd-ask-password"; then
        derror "systemd-cryptsetup needs systemd-ask-password in the initramfs."
        return 1
    fi

    if ! dracut_module_included "systemd-tmpfiles"; then
        derror "systemd-cryptsetup needs tmpfiles in the initramfs."
        return 1
    fi

    # Return 255 to only include the module, if another module requires it.
    return 255

}

# Module dependency requirements.
depends() {

    # This module has external dependency on the systemd module.
    echo dm rootfs-block systemd systemd-ask-password systemd-tmpfiles
    # Return 0 to include the dependent systemd module in the initramfs.
    return 0

}

# Install kernel required file(s) for the module in the initramfs.
installkernel() {
        hostonly="" instmods drbg
        instmods dm_crypt

        # in case some of the crypto modules moved from compiled in
        # to module based, try to install those modules
        # best guess
        [[ $hostonly ]] || [[ $mount_needs ]] && {
            # dmsetup returns s.th. like
            # cryptvol: 0 2064384 crypt aes-xts-plain64 :64:logon:cryptsetup:....
            dmsetup table | while read name _ _ is_crypt cipher _; do
            [[ $is_crypt != "crypt" ]] && continue
                # get the device name
                name=/dev/$(dmsetup info -c --noheadings -o blkdevname ${name%:})
                # check if the device exists as a key in our host_fs_types
                if [[ ${host_fs_types[$name]+_} ]]; then
                    # split the cipher aes-xts-plain64 in pieces
                    _OLD_IFS=$IFS
                    IFS='-:'
                    set -- $cipher
                    IFS=$_OLD_IFS
                    # try to load the cipher part with "crypto-" prepended
                    # in non-hostonly mode
                    hostonly= instmods $(for k in "$@"; do echo "crypto-$k";done)
                fi
        done
        }
    return 0
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

# Install the required file(s) for the module in the initramfs.
install() {

    inst_hook cmdline 30 "$moddir/parse-crypt.sh"
    inst_simple "$moddir/crypt-lib.sh" "/lib/dracut-crypt-lib.sh"
    inst_script "$moddir/crypt-run-generator.sh" "/sbin/crypt-run-generator"
    inst_multiple -o \

        # Install the systemd type service unit for systemd-cryptsetup.
        $tmpfilesdir/cryptsetup.conf \
        $systemdutildir/systemd-cryptsetup \
        $systemdutildir/system-generators/systemd-cryptsetup-generator \
        $systemdsystemunitdir/cryptsetup.target \
        $systemdsystemunitdir/cryptsetup-pre.target \
        $systemdsystemunitdir/remote-cryptsetup.target \
        $systemdsystemunitdir/sysinit.target.wants/cryptsetup.target \
        $systemdsystemunitdir/initrd-root-device.target.wants/remote-cryptsetup.target

        if [[ $hostonly_cmdline == "yes" ]]; then
            local _cryptconf=$(cmdline)
            [[ $_cryptconf ]] && printf "%s\n" "$_cryptconf" >> "${initdir}/etc/cmdline.d/crypsetup.conf"
        fi

        if [[ $hostonly ]] && [[ -f $dracutsysrootdir/etc/crypttab ]]; then
        # filter /etc/crypttab for the devices we need
        while read _mapper _dev _luksfile _luksoptions || [ -n "$_mapper" ]; do
            [[ $_mapper = \#* ]] && continue
            [[ $_dev ]] || continue

            [[ $_dev == PARTUUID=* ]] && \
            _dev="/dev/disk/by-partuuid/${_dev#PARTUUID=}"

            [[ $_dev == UUID=* ]] && \
            _dev="/dev/disk/by-uuid/${_dev#UUID=}"

            [[ $_dev == ID=* ]] && \
            _dev="/dev/disk/by-id/${_dev#ID=}"

            echo "$_dev $(blkid $_dev -s UUID -o value)" >> "${initdir}/etc/block_uuid.map"

            # loop through the options to check for the force option
            luksoptions=${_luksoptions}
            OLD_IFS="${IFS}"
            IFS=,
            set -- ${luksoptions}
            IFS="${OLD_IFS}"

            forceentry=""
            while [ $# -gt 0 ]; do
                case $1 in
                    force)
                        forceentry="yes"
                        break
                        ;;
                esac
                shift
            done

            # include the entry regardless
            if [ "${forceentry}" = "yes" ]; then
                echo "$_mapper $_dev $_luksfile $_luksoptions"
            else
                for _hdev in "${!host_fs_types[@]}"; do
                    [[ ${host_fs_types[$_hdev]} == "crypto_LUKS" ]] || continue
                    if [[ $_hdev -ef $_dev ]] || [[ /dev/block/$_hdev -ef $_dev ]]; then
                        echo "$_mapper $_dev $_luksfile $_luksoptions"
                        break
                    fi
                done
            fi
        done < $dracutsysrootdir/etc/crypttab > $initdir/etc/crypttab
        mark_hostonly /etc/crypttab
        fi


        _arch=${DRACUT_ARCH:-$(uname -m)}
        inst_libdir_file {"tls/$_arch/",tls/,"$_arch/",}"libcryptsetup.so.*" \

    dracut_need_initqueue
}
