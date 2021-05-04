#!/bin/bash
# This file is part of dracut.
# SPDX-License-Identifier: GPL-2.0-or-later

# Prerequisite check(s) for module.
check() {

    # If the binary(s) requirements are not fulfilled the module can't be installed
    require_binaries \
        systemd-ask-password \
        systemd-tty-ask-password-agent \
        || return 1

    # Return 255 to only include the module, if another module requires it.
    return 255

}

# Module dependency requirements.
depends() {

    # Return 0 to include the dependent module(s) in the initramfs.
    return 0

}

# Install the required file(s) for the module in the initramfs.
install() {

    inst_multiple -o \
        "$systemdsystemunitdir"/systemd-ask-password-console.path \
        "$systemdsystemunitdir"/systemd-ask-password-console.service \
        "$systemdsystemunitdir"/multi-user.target.wants/systemd-ask-password-wall.path \
        "$systemdsystemunitdir"/sysinit.target.wants/systemd-ask-password-console.path \
        systemd-ask-password \
        systemd-tty-ask-password-agent

    # Enable the systemd type service unit for systemd-ask-password.
    $SYSTEMCTL -q --root "$initdir" enable systemd-ask-password-console.service

    # Install systemd-ask-password plymouth units if plymouth is enabled.
    if dracut_module_included "plymouth"; then
        inst_multiple -o \
            "$systemdsystemunitdir"/systemd-ask-password-plymouth.path \
            "$systemdsystemunitdir"/systemd-ask-password-plymouth.service

        $SYSTEMCTL -q --root "$initdir" enable systemd-ask-password-plymouth.service
    fi

    # Uncomment this section if the usecase for wall module in the initramfs arises.
    # Install systemd-ask-password wall units if <wall module> is enabled.
    #if dracut_module_included "<wall module>"; then
    #    inst_multiple -o \
    #        $systemdsystemunitdir/systemd-ask-password-wall.path \
    #        $systemdsystemunitdir/systemd-ask-password-wall.service \
    #        $systemdsystemunitdir/multi-user.target.wants/systemd-ask-password-wall.path \
    #
    #    $SYSTEMCTL -q --root "$initdir" enable systemd-ask-password-wall.service
    #fi
}
