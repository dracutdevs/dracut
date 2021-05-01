#!/bin/bash
# This file is part of dracut.
# SPDX-License-Identifier: GPL-2.0-or-later

# Prerequisite check(s) for module.
check() {

    # If the binary(s) requirements are not fulfilled the module can't be installed
    require_binaries \
        resolvectl \
        "$systemdutildir"/systemd-resolved \
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

    inst_simple "$moddir/resolved-tmpfile-dracut.conf" "$tmpfilesdir/resolved-tmpfile-dracut.conf"

    inst_multiple -o \
        "$dbussystem"/org.freedesktop.resolve1.conf \
        "$dbussystemservices"/org.freedesktop.resolve1.service \
        "$systemdutildir"/resolv.conf \
        "$systemdutildir"/resolved.conf \
        "$systemdutildir/resolved.conf.d/*.conf" \
        "$systemdutildir"/systemd-resolved \
        "$systemdsystemunitdir"/systemd-resolved.service \
        "$systemdsystemunitdir/systemd-resolved.service.d/*.conf" \
        resolvectl

    # Enable systemd type unit(s)
    $SYSTEMCTL -q --root "$initdir" enable systemd-resolved.service

    # Install the hosts local user configurations if enabled.
    if [[ $hostonly ]]; then
        inst_multiple -H -o \
            "$systemdutilconfdir"/resolved.conf \
            "$systemdutilconfdir/resolved.conf.d/*.conf" \
            "$systemdsystemconfdir"/systemd-resolved.service \
            "$systemdsystemconfdir/systemd-resolved.service/*.conf"
    fi
}
