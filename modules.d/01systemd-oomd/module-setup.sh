#!/bin/bash
# This file is part of dracut.
# SPDX-License-Identifier: GPL-2.0-or-later

# Prerequisite check(s) for module.
check() {

    # If the binary(s) requirements are not fulfilled the module can't be installed.
    require_binaries \
        oomctl \
        "$systemdutildir"/systemd-oomd \
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

    inst_multiple -o \
        "$dbussystem"/org.freedesktop.oom1.conf \
        "$dbussystemservices"/org.freedesktop.oom1.service \
        "$systemdutildir"/systemd-oomd \
        "$systemdsystemunitdir"/systemd-oomd.service \
        "$systemdsystemunitdir/systemd-oomd.service.d/*.conf" \
        "$systemdsystemunitdir"/systemd-oomd.socket \
        "$systemdsystemunitdir/systemd-oomd.socket.d/*.conf" \
        "$sysusers"/systemd-oom.conf \
        oomctl

    # Enable systemd type unit(s)
    for i in \
        systemd-oomd.service \
        systemd-oomd.socket; do
        $SYSTEMCTL -q --root "$initdir" enable "$i"
    done

    # Install the hosts local user configurations if enabled.
    if [[ $hostonly ]]; then
        inst_multiple -H -o \
            "$systemdutilconfdir"/oomd.conf \
            "$systemdsystemconfdir"/systemd-oomd.service \
            "$systemdsystemconfdir/systemd-oomd.service.d/*.conf" \
            "$systemdsystemconfdir"/systemd-oomd.socket \
            "$systemdsystemconfdir/systemd-oomd.socket.d/*.conf" \
            "$sysusersconfdir"/systemd-oom.conf
    fi

}
