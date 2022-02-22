#!/bin/bash
# This file is part of dracut.
# SPDX-License-Identifier: GPL-2.0-or-later

# Prerequisite check(s) for module.
check() {

    # If the binary(s) requirements are not fulfilled the module can't be installed
    require_binaries \
        "$systemdutildir"/systemd-timesyncd \
        "$systemdutildir"/systemd-time-wait-sync \
        || return 1

    # Return 255 to only include the module, if another module requires it.
    return 255

}

# Module dependency requirements.
depends() {

    # This module has external dependency on other module(s).
    echo dbus systemd-sysusers systemd-timedated
    # Return 0 to include the dependent module(s) in the initramfs.
    return 0

}

# Install the required file(s) and directories for the module in the initramfs.
install() {

    # Enable this if networkd ( not the module ) is disabled at build time and you want to use timesyncd
    # inst_simple "$moddir/timesyncd-tmpfile-dracut.conf" "$tmpfilesdir/timesyncd-tmpfile-dracut.conf"

    inst_multiple -o \
        "$dbussystem"/org.freedesktop.timesync1.conf \
        "$dbussystemservices"/org.freedesktop.timesync1.service \
        "$systemdutildir/ntp-units.d/*.list" \
        "$systemdutildir"/systemd-timesyncd \
        "$systemdutildir"/systemd-time-wait-sync \
        "$systemdutildir/timesyncd.conf.d/*.conf" \
        "$systemdsystemunitdir"/systemd-timesyncd.service \
        "$systemdsystemunitdir/systemd-timesyncd.service.d/*.conf" \
        "$systemdsystemunitdir"/systemd-time-wait-sync.service \
        "$systemdsystemunitdir/systemd-time-wait-sync.service.d/*.conf" \
        "$sysusers"/systemd-timesync.conf

    # Enable systemd type unit(s)
    for i in \
        systemd-timesyncd.service \
        systemd-time-wait-sync.service; do
        $SYSTEMCTL -q --root "$initdir" enable "$i"
    done

    # Install the hosts local user configurations if enabled.
    if [[ $hostonly ]]; then
        inst_multiple -H -o \
            "$systemdutilconfdir/ntp-units.d/*.list" \
            "$systemdutilconfdir"/timesyncd.conf \
            "$systemdutilconfdir/timesyncd.conf.d/*.conf" \
            "$systemdsystemconfdir"/systemd-timesyncd.service \
            "$systemdsystemconfdir/systemd-timesyncd.service.d/*.conf" \
            "$systemdsystemunitdir"/systemd-time-wait-sync.service \
            "$systemdsystemunitdir/systemd-time-wait-sync.service.d/*.conf" \
            "$sysusersconfdir"/systemd-timesync.conf
    fi
}
