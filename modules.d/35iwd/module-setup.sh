#!/bin/sh
# This file is part of dracut.
# SPDX-License-Identifier: GPL-2.0-or-later

# Prerequisite check(s) for module.
check() {

    # If the binary(s) requirements are not fulfilled
    # return 1 to not include the binary.
    require_binaries hwsim || return 1
    require_binaries iwctl || return 1
    require_binaries iwmon || return 1

    # If the module dependency requirements are not fulfilled
    # return 1 to not include the required module(s).
    if ! dracut_module_included "systemd"; then
        derror "iwd needs systemd in the initramfs."
        return 1
    fi

    if ! dracut_module_included "dbus-broker"; then
        derror "iwd needs dbus-broker in the initramfs."
        return 1
    fi

    # Return 255 to only include the module, if another module requires it.
    return 255

}

# Module dependency requirements.
depends() {

    # This module has external dependency on modules.
    echo "systemd dbus-broker"
    # Return 0 to include the dependent module(s) in the initramfs.
    return 0

}

# Install the required file(s) for the module in the initramfs.
install() {

    inst_multiple -o \
        # When distributions use CONFIG_PKCS8_PRIVATE_KEY_PARSER=m kernel option,
        # using keyctl(2) will fail for loading PKCS#8 private keys since there
        # is no automatic module loading for key type parsers. This entry ensures
        # that the kernel module pkcs8_key_parser.ko is loaded at boot time.
        $modulesload/pkcs8.conf
        # Install the dbus configuration files for iwd.
        $dbussystem/ead-dbus.conf \
        $dbussystem/hwsim-dbus.conf \
        $dbussystem/iwd-dbus.conf \
        $dbussystemservices/net.connman.ead.service \
        $dbussystemservices/net.connman.iwd.services \
        # Install the systemd type service unit for iwd.
        $systemdsystemunitdir/ead.service \
        $systemdsystemunitdir/iwd.service \
        # Install the binary executable(s) for iwd.
        hwsim iwctl iwm \
        # Instal the library executable(s) for iwd
        /usr/libexec/iwd /usr/libexec/ead

        # Install local user configurations if host only us enabled.
        if [[ $hostonly ]]; then
            inst_multiple -H -o \
            /etc/iwd/main.conf \
            $modulesloadconfdir/pkcs8.conf \
            $dbussystemconfdir/ead-dbus.conf \
            $dbussystemconfdir/hwsim-dbus.conf \
            $dbussystemconfdir/iwd-dbus.conf \
            $dbussystemservices/net.connman.ead.service \
            $dbussystemservices/net.connman.iwd.service \
            $systemdsystemconfdir/ead.service \
            $systemdsystemconfdir/ead.service.d/*.conf \
            $systemdsystemconfdir/iwd.service \
            $systemdsystemconfdir/iwd.service.d/*.conf \
            /var/lib/ead/* \
            /var/lib/iwd/.* \
            /var/lib/iwd/* \
            /var/lib/hotspot/*
            ${NULL}
        fi

        # Enable the systemd type service unit for ead.
        # systemctl -q --root "$initdir" enable ead.service

        # Enable the systemd type service unit for iwd.
        systemctl -q --root "$initdir" enable iwd.service

}
