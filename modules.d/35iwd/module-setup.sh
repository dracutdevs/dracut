#!/bin/bash
# This file is part of dracut.
# SPDX-License-Identifier: GPL-2.0-or-later

# Prerequisite check(s) for module.
check() {

    # If the binary(s) requirements are not fulfilled the module can't be installed.
    require_binaries \
        iwmon \
        iwctl \
        || return 1

    require_any_binary \
        /usr/lib/iwd \
        /usr/libexec/iwd \
        || return 1

    # Return 255 to only include the module, if another module requires it.
    return 255

}

# Module dependency requirements.
depends() {

    # This module has external dependency on other module(s).
    echo dbus systemd-modules-load systemd-resolved
    # Return 0 to include the dependent module(s) in the initramfs.
    return 0

}

installkernel() {
    instmods '=drivers/net/wireless'
}

# Install the required file(s) and directories for the module in the initramfs.
install() {

    inst_rules "$moddir/99-iwd.rules"
    inst_simple "$moddir/iwd.service" "$systemdsystemunitdir"/iwd.service
    inst_simple "$moddir/iwd_main.conf" "/etc/iwd/main.conf"
    inst_simple "$moddir/iwd-tmpfile.conf" "$tmpfilesdir/iwd-tmpfile.conf"

    if dracut_module_included "network-manager"; then
        inst_simple "$moddir/iwd_backend.conf" "/etc/NetworkManager/conf.d/iwd_backend.conf"
    fi

    inst_multiple -o \
        /usr/lib/firmware/regulatory.db \
        /usr/lib/firmware/regulatory.db.p7s \
        "$modulesload"/pkcs8.conf \
        "$dbussystem"/iwd-dbus.conf \
        "$dbussystemservices"/net.connman.iwd.services \
        "$systemdsystemunitdir/iwd.service.d/*.conf" \
        /usr/lib/iwd \
        /usr/libexec/iwd \
        iwctl iwmon

    # Enable systemd type units
    $SYSTEMCTL -q --root "$initdir" enable iwd.service

    # Install the hosts local user configurations if enabled.
    if [[ $hostonly ]]; then
        inst_multiple -H -o \
            /etc/iwd/main.conf \
            "$modulesloadconfdir"/pkcs8.conf \
            "$dbussystemconfdir"/iwd-dbus.conf \
            "$dbussystemservices"/net.connman.iwd.service \
            "$systemdsystemconfdir"/iwd.service \
            "$systemdsystemconfdir/iwd.service.d/*.conf" \
            /var/lib/iwd/.* \
            /var/lib/iwd/* \
            /var/lib/iwd/hotspot/*
    fi

    # Install required libraries.
    _arch=${DRACUT_ARCH:-$(uname -m)}
    inst_libdir_file {"tls/$_arch/",tls/,"$_arch/",}"libell.so.*"

}
