#!/bin/bash

# called by dracut
check() {
    local fs
    # if cryptsetup is not installed, then we cannot support encrypted devices.
    require_any_binary "$systemdutildir"/systemd-cryptsetup cryptsetup || return 1

    [[ $hostonly ]] || [[ $mount_needs ]] && {
        for fs in "${host_fs_types[@]}"; do
            [[ $fs == "crypto_LUKS" ]] && return 0
        done
        return 255
    }

    return 0
}

# called by dracut
depends() {
    local deps
    deps="dm rootfs-block"
    if [[ $hostonly && -f "$dracutsysrootdir"/etc/crypttab ]]; then
        if grep -q -e "fido2-device=" -e "fido2-cid=" "$dracutsysrootdir"/etc/crypttab; then
            deps+=" fido2"
        fi
        if grep -q "pkcs11-uri" "$dracutsysrootdir"/etc/crypttab; then
            deps+=" pkcs11"
        fi
        if grep -q "tpm2-device=" "$dracutsysrootdir"/etc/crypttab; then
            deps+=" tpm2-tss"
        fi
    fi
    echo "$deps"
    return 0
}

# called by dracut
installkernel() {
    hostonly="" instmods drbg
    instmods dm_crypt

    # in case some of the crypto modules moved from compiled in
    # to module based, try to install those modules
    # best guess
    if [[ $hostonly ]] || [[ $mount_needs ]]; then
        # dmsetup returns s.th. like
        # cryptvol: 0 2064384 crypt aes-xts-plain64 :64:logon:cryptsetup:....
        dmsetup table | while read -r name _ _ is_crypt cipher _; do
            [[ $is_crypt == "crypt" ]] || continue
            # get the device name
            name=/dev/$(dmsetup info -c --noheadings -o blkdevname "${name%:}")
            # check if the device exists as a key in our host_fs_types (even with null string)
            # shellcheck disable=SC2030  # this is a shellcheck bug
            if [[ ${host_fs_types[$name]+_} ]]; then
                # split the cipher aes-xts-plain64 in pieces
                IFS='-:' read -ra mods <<< "$cipher"
                # try to load the cipher part with "crypto-" prepended
                # in non-hostonly mode
                hostonly='' instmods "${mods[@]/#/crypto-}" "crypto-$cipher"
            fi
        done
    else
        instmods "=crypto"
    fi
    return 0
}

# called by dracut
cmdline() {
    local dev UUID
    # shellcheck disable=SC2031
    for dev in "${!host_fs_types[@]}"; do
        [[ ${host_fs_types[$dev]} != "crypto_LUKS" ]] && continue

        UUID=$(
            blkid -u crypto -o export "$dev" \
                | while read -r line || [ -n "$line" ]; do
                    [[ ${line#UUID} == "$line" ]] && continue
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

    # systemd only - check if the key file is a socket and if so, include required units
    install_socket_units() {
        local volume_name=$1
        local socket_path=$2

        # ignore paths followed by a device specification
        if [[ $socket_path == *":"* ]]; then
            return
        fi

        # if no explicit path is provided, try to include units for auto-discoverable keys
        if [[ $socket_path == "-" ]] || [[ $socket_path == "none" ]]; then
            socket_path="/run/cryptsetup-keys.d/$volume_name.key"
        fi

        if ! dracut_module_included "systemd"; then
            return
        fi

        find "$systemdsystemunitdir" "$systemdsystemconfdir" -type f -name "*.socket" | while read -r socket_unit; do
            # systemd-cryptsetup utility only supports SOCK_STREAM (ListenStream) sockets, so we ignore
            # other types like SOCK_DGRAM (ListenDatagram), SOCK_SEQPACKET (ListenSequentialPacket), etc.
            if ! grep -E -q "^ListenStream\s*=\s*$socket_path$" "$socket_unit"; then
                continue
            fi

            service_name=$(grep -E "^Service\s*=\s*" "$socket_unit" | cut -d= -f2)

            if [ -z "$service_name" ]; then
                # if no explicit Service= is defined, construct the service name based on the socket unit's name
                if grep -P -q "^Accept\s*=\s*(?i)(1|yes|y|true|t|on)$" "$socket_unit"; then
                    # if Accept is truthy, assemble a service template
                    service_name=$(basename "$socket_unit" .socket)"@.service"
                else
                    # otherwise, just replace .socket with .service
                    service_name=$(basename "$socket_unit" .socket)".service"
                fi
            fi

            # this assumes the service file is in the same directory as the socket file,
            # which is a common configuration but not guaranteed.
            if ! inst_multiple -H "${socket_unit%/*}/$service_name" "$socket_unit"; then
                continue
            fi

            # sanity check - all units which use default dependencies will depend on sysinit.target,
            # which itself depends on cryptsetup.target. This could lead to either:
            #   a) systemd-cryptsetup falling back to a passphrase prompt due to a missing socket file
            #   b) a deadlock caused by a circular dependency (service unit -> sysinit.target -> cryptsetup.target -> service unit)
            if ! grep -P -q "^DefaultDependencies\s*=\s*(?i)(0|no|n|false|f|off)" "$socket_unit"; then
                dwarning "crypt: $socket_unit: default dependencies are not disabled," \
                    "the socket file may not exist by the time systemd-cryptsetup gets executed"
            fi

            if ! grep -P -q "^DefaultDependencies\s*=\s*(?i)(0|no|n|false|f|off)" "${socket_unit%/*}/$service_name"; then
                dwarning "crypt: ${socket_unit%/*}/$service_name: default dependencies are not disabled," \
                    "the service unit may encounter a deadlock due to a circular dependency"
            fi

            socket_unit_basename=$(basename "$socket_unit")
            inst_multiple -H -o \
                "$systemdsystemunitdir"/sockets.target.wants/"$socket_unit_basename" \
                "$systemdsystemconfdir"/sockets.target.wants/"$socket_unit_basename"
            break
        done
    }

    if [[ $hostonly_cmdline == "yes" ]]; then
        local _cryptconf
        _cryptconf=$(cmdline)
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

    if [[ $hostonly ]] && [[ -f $dracutsysrootdir/etc/crypttab ]]; then
        # filter /etc/crypttab for the devices we need
        while read -r _mapper _dev _luksfile _luksoptions || [ -n "$_mapper" ]; do
            [[ $_mapper == \#* ]] && continue
            [[ $_dev ]] || continue

            [[ $_dev == PARTUUID=* ]] \
                && _dev="/dev/disk/by-partuuid/${_dev#PARTUUID=}"

            [[ $_dev == UUID=* ]] \
                && _dev="/dev/disk/by-uuid/${_dev#UUID=}"

            [[ $_dev == ID=* ]] \
                && _dev="/dev/disk/by-id/${_dev#ID=}"

            echo "$_dev $(blkid "$_dev" -s UUID -o value)" >> "${initdir}/etc/block_uuid.map"

            # loop through the options to check for the force option
            luksoptions=${_luksoptions}
            OLD_IFS="${IFS}"
            IFS=,
            # shellcheck disable=SC2086
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
                install_socket_units "$_mapper" "$_luksfile"
            else
                # shellcheck disable=SC2031
                for _hdev in "${!host_fs_types[@]}"; do
                    [[ ${host_fs_types[$_hdev]} == "crypto_LUKS" ]] || continue
                    if [[ $_hdev -ef $_dev ]] || [[ /dev/block/$_hdev -ef $_dev ]]; then
                        echo "$_mapper $_dev $_luksfile $_luksoptions"
                        install_socket_units "$_mapper" "$_luksfile"
                        break
                    fi
                done
            fi
        done < "$dracutsysrootdir"/etc/crypttab > "$initdir"/etc/crypttab
        mark_hostonly /etc/crypttab
    fi

    inst_simple "$moddir/crypt-lib.sh" "/lib/dracut-crypt-lib.sh"
    inst_script "$moddir/crypt-run-generator.sh" "/sbin/crypt-run-generator"

    if dracut_module_included "systemd"; then
        # the cryptsetup targets are already pulled in by 00systemd, but not
        # the enablement symlinks
        inst_multiple -o \
            "$tmpfilesdir"/cryptsetup.conf \
            "$systemdutildir"/system-generators/systemd-cryptsetup-generator \
            "$systemdutildir"/systemd-cryptsetup \
            "$systemdsystemunitdir"/systemd-ask-password-console.path \
            "$systemdsystemunitdir"/systemd-ask-password-console.service \
            "$systemdsystemunitdir"/cryptsetup.target \
            "$systemdsystemunitdir"/sysinit.target.wants/cryptsetup.target \
            "$systemdsystemunitdir"/remote-cryptsetup.target \
            "$systemdsystemunitdir"/initrd-root-device.target.wants/remote-cryptsetup.target \
            systemd-ask-password systemd-tty-ask-password-agent
    fi

    # Install required libraries.
    _arch=${DRACUT_ARCH:-$(uname -m)}
    inst_libdir_file \
        {"tls/$_arch/",tls/,"$_arch/",}"/ossl-modules/fips.so" \
        {"tls/$_arch/",tls/,"$_arch/",}"/ossl-modules/legacy.so"

    dracut_need_initqueue
}
