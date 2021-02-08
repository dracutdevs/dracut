#!/bin/sh
# This file is part of dracut.
# SPDX-License-Identifier: GPL-2.0-or-later

# Prerequisite check(s) for module.
check() {

    # If the binary(s) requirements are not fulfilled
    # return 1 to not include the binary.
    require_binaries systemd-sysusers || return 1

    # If the module dependency requirements are not fulfilled
    # return 1 to not include the required module(s).
    if ! dracut_module_included "systemd"; then
        derror "systemd-sysuser needs systemd in the initramfs."
        return 1
    fi

    # Return 255 to only include the module, if another module requires it.
    return 255

}

# Module dependency requirements.
depends() {

    # This module has external dependency on the systemd module.
    echo systemd
    # Return 0 to include the dependent systemd module in the initramfs.
    return 0

}

# Install the required file(s) for the module in the initramfs.
install() {

    inst_multiple -o \
        # Install the system users and groups configuration file.
        $sysusers/basic.conf \
        # Install the systemd users and groups configuration file.
        $sysusers/systemd.conf \
        # Install the systemd type service unit for sysusers.
        $systemdsystemunitdir/systemd-sysusers.service \
        # Install the binary executable(s) for sysusers.
        systemd-sysusers

        # Install the hosts local user configurations if enabled.
        if [[ $hostonly ]]; then
            inst_multiple -H -o \
            $sysusersconfdir/basic.conf \
            $sysusersconfdir/systemd.conf \
            $systemdsystemconfdir/systemd-sysusers.service \
            $systemdsystemconfdir/systemd-sysusers.service.d/*.conf
            ${NULL}
        fi

        # Enable the systemd type service unit for sysusers.
        systemctl -q --root "$initdir" enable systemd-sysusers.service

}
