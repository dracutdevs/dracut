#!/bin/sh
# This file is part of dracut.
# SPDX-License-Identifier: GPL-2.0-or-later

# Prerequisite check(s) for module.
check() {

    # If the binary(s) requirements are not fulfilled
    # return 1 to not include the binary.
    require_binaries systemd-ask-password || return 1
    require_binaries systemd-tty-ask-password-agent || return 1

    # If the module dependency requirements are not fulfilled
    # return 1 to not include the required module(s).
    if ! dracut_module_included "systemd"; then
        derror "systemd-ask-password needs systemd in the initramfs."
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

        # Install the systemd type service unit for systemd-ask-password.
        $systemdsystemunitdir/systemd-ask-password-console.path \
        $systemdsystemunitdir/systemd-ask-password-console.service \
        $systemdsystemunitdir/multi-user.target.wants/systemd-ask-password-wall.path \
        $systemdsystemunitdir/sysinit.target.wants/systemd-ask-password-console.path

        # Install the binary executable(s) for systemd-ask-password.
        systemd-ask-password systemd-tty-ask-password-agent

        # Enable the systemd type service unit for systemd-ask-password.
        systemctl -q --root "$initdir" enable systemd-ask-password-console.service

        # Install systemd-ask-password plymouth units if plymouth is enabled.
        if dracut_module_included "plymouth"; then
            inst_multiple -o \
                $systemdsystemunitdir/systemd-ask-password-plymouth.path \
                $systemdsystemunitdir/systemd-ask-password-plymouth.service

        # Enable the systemd type service unit for systemd-ask-password.
                systemctl -q --root "$initdir" enable systemd-ask-password-plymouth.service
        fi

        # Uncomment this section if the usecase for wall module in the initramfs arises.
         # Install systemd-ask-password wall units if <wall module> is enabled.
         #if dracut_module_included "<wall module>"; then
         #    inst_multiple -o \
         #        $systemdsystemunitdir/systemd-ask-password-wall.path \
         #        $systemdsystemunitdir/systemd-ask-password-wall.service \
         #        $systemdsystemunitdir/multi-user.target.wants/systemd-ask-password-wall.path
         #
         # Enable the systemd type service unit for systemd-ask-password-wall.
         #systemctl -q --root "$initdir" enable systemd-ask-password-wall.service
         #fi
}
