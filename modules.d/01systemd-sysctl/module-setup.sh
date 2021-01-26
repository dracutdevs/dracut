#!/bin/sh
# This file is part of dracut.
# SPDX-License-Identifier: GPL-2.0-or-later

# Prerequisite check(s) for module.
check() {

    # If the binary(s) requirements are not fulfilled the module can't be installed
    require_binaries $systemdutildir/systemd-sysctl || return 1

    # Return 255 to only include the module, if another module requires it.
    return 255

}

# Module dependency requirements.
depends() {

    # This module has external dependency on other module(s).
    echo systemd systemd-modules-load
    # Return 0 to include the dependent module(s) in the initramfs.
    return 0

}

# Install the required file(s) for the module in the initramfs.
install() {

    inst_multiple -o \
        $sysctld/*.conf \
        $systemdsystemunitdir/systemd-sysctl.service \
        $systemdsystemunitdir/sysinit.target.wants/systemd-sysctl.service \
        $systemdutildir/systemd-sysctl

    # Install the hosts local user configurations if enabled.
    if [[ $hostonly ]]; then
        inst_multiple -H -o \
            /etc/sysctl.conf \
            $sysctldconfdir/*.conf \
            $systemdsystemconfdir/systemd-sysctl.service \
            $systemdsystemconfdir/systemd-sysctl.service.d/*.conf \
            ${NULL}
    fi

    # Enable the systemd type service unit for sysctl.
    $SYSTEMCTL -q --root "$initdir" enable systemd-sysctl.service

}
