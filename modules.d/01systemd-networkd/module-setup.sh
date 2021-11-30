#!/bin/bash
# This file is part of dracut.
# SPDX-License-Identifier: GPL-2.0-or-later

# Prerequisite check(s) for module.
check() {
    [[ $mount_needs ]] && return 1

    # If the binary(s) requirements are not fulfilled the module can't be installed
    require_binaries ip networkctl \
        "$systemdutildir"/systemd-networkd \
        "$systemdutildir"/systemd-network-generator \
        "$systemdutildir"/systemd-networkd-wait-online \
        || return 1

    # Return 255 to only include the module, if another module requires it.
    return 255

}

# Module dependency requirements.
depends() {

    # This module has external dependency on other module(s).
    echo dbus kernel-network-modules systemd-sysusers
    # Return 0 to include the dependent module(s) in the initramfs.
    return 0

}

# Install the required file(s) and directories for the module in the initramfs.
install() {

    inst_multiple -o \
        "$dbussystem"/org.freedesktop.network1.conf \
        "$dbussystemservices"/org.freedesktop.network1.service \
        "$systemdutildir"/networkd.conf \
        "$systemdutildir/networkd.conf.d/*.conf" \
        "$systemdutildir"/systemd-networkd \
        "$systemdutildir"/systemd-network-generator \
        "$systemdutildir"/systemd-networkd-wait-online \
        "$systemdutildir"/network/80-container-host0.network \
        "$systemdutildir"/network/80-container-ve.network \
        "$systemdutildir"/network/80-container-vz.network \
        "$systemdutildir"/network/80-vm-vt.network \
        "$systemdutildir"/network/80-wifi-adhoc.network \
        "$systemdutildir"/network/99-default.link \
        "$systemdsystemunitdir"/systemd-networkd.service \
        "$systemdsystemunitdir"/systemd-networkd.socket \
        "$systemdsystemunitdir"/systemd-network-generator.service \
        "$systemdsystemunitdir"/systemd-networkd-wait-online.service \
        "$systemdsystemunitdir"/systemd-network-generator.service \
        "$sysusers"/systemd-network.conf \
        networkctl ip

    # Enable systemd type units
    for i in \
        systemd-networkd.service \
        systemd-networkd.socket \
        systemd-network-generator.service \
        systemd-networkd-wait-online.service; do
        $SYSTEMCTL -q --root "$initdir" enable "$i"
    done

    # Install the hosts local user configurations if enabled.
    if [[ $hostonly ]]; then
        inst_multiple -H -o \
            "$systemdutilconfdir"/networkd.conf \
            "$systemdutilconfdir/networkd.conf.d/*.conf" \
            "$systemdutilconfdir/network/*" \
            "$systemdsystemconfdir"/systemd-networkd.service \
            "$systemdsystemconfdir/systemd-networkd.service/*.conf" \
            "$systemdsystemunitdir"/systemd-networkd.socket \
            "$systemdsystemunitdir/systemd-networkd.socket/*.conf" \
            "$systemdsystemconfdir"/systemd-network-generator.service \
            "$systemdsystemconfdir/systemd-network-generator.service/*.conf" \
            "$systemdsystemconfdir"/systemd-networkd-wait-online.service \
            "$systemdsystemconfdir/systemd-networkd-wait-online.service/*.conf" \
            "$sysusersconfdir"/systemd-network.conf
    fi
}
