#!/bin/bash
# This file is part of dracut.
# SPDX-License-Identifier: GPL-2.0-or-later

# Prerequisite check(s) for module.
check() {

    # If the binary(s) requirements are not fulfilled the module can't be installed.
    require_binaries \
        hostnamectl \
        "$systemdutildir"/systemd-hostnamed \
        || return 1

    # Return 255 to only include the module, if another module requires it.
    return 255

}

# Module dependency requirements.
depends() {

    # This module has external dependency on other module(s).
    echo dbus systemd-sysusers
    # Return 0 to include the dependent module(s) in the initramfs.
    return 0

}

# Install the required file(s) and directories for the module in the initramfs.
install() {

    inst_simple "$moddir/systemd-hostname-dracut.conf" "$sysusers/systemd-hostname-dracut.conf"
    inst_simple "$moddir/org.freedesktop.hostname1_dracut.conf" "$dbussystem/org.freedesktop.hostname1_dracut.conf"
    inst_simple "$moddir/99-systemd-networkd-dracut.conf" "$systemdsystemunitdir/systemd-hostnamed.service.d/99-systemd-networkd-dracut.conf"

    inst_multiple -o \
        "$dbussystem"/org.freedesktop.hostname1.conf \
        "$dbussystemservices"/org.freedesktop.hostname1.service \
        "$systemdutildir"/systemd-hostnamed \
        "$systemdsystemunitdir"/systemd-hostnamed.service \
        "$systemdsystemunitdir/systemd-hostnamed.service.d/*.conf" \
        hostnamectl

    # Install the hosts local user configurations if enabled.
    if [[ $hostonly ]]; then
        inst_multiple -H -o \
            /etc/hostname \
            "$systemdsystemconfdir"/systemd-hostnamed.service \
            "$systemdsystemconfdir/systemd-hostnamed.service.d/*.conf"
    fi
}
