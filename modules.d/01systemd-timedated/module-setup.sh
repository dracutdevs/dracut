#!/bin/bash
# This file is part of dracut.
# SPDX-License-Identifier: GPL-2.0-or-later

# Prerequisite check(s) for module.
check() {

    # If the binary(s) requirements are not fulfilled the module can't be installed
    require_binaries \
        timedatectl \
        "$systemdutildir"/systemd-timedated \
        || return 1

    # Return 255 to only include the module, if another module requires it.
    return 255

}

# Module dependency requirements.
depends() {

    # This module has external dependency on other module(s).
    echo dbus
    # Return 0 to include the dependent module(s) in the initramfs.
    return 0

}

# Install the required file(s) and directories for the module in the initramfs.
install() {

    inst_multiple -o \
        "$dbussystem"/org.freedesktop.timedate1.conf \
        "$dbussystemservices"/org.freedesktop.timedate1.service \
        "$systemdutildir"/systemd-timedated \
        "$systemdsystemunitdir"/systemd-timedated.service \
        "$systemdsystemunitdir"/dbus-org.freedesktop.timedate1.service \
        timedatectl

    # Install the hosts local user configurations if enabled.
    if [[ $hostonly ]]; then
        inst_multiple -H -o \
            "$systemdsystemconfdir"/systemd-timedated.service \
            "$systemdsystemconfdir/systemd-timedated.service.d/*.conf"
    fi
}
