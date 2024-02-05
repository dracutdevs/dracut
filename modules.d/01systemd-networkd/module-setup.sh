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
        "$tmpfilesdir"/systemd-network.conf \
        "$dbussystem"/org.freedesktop.network1.conf \
        "$dbussystemservices"/org.freedesktop.network1.service \
        "$systemdutildir"/networkd.conf \
        "$systemdutildir/networkd.conf.d/*.conf" \
        "$systemdutildir"/systemd-networkd \
        "$systemdutildir"/systemd-network-generator \
        "$systemdutildir"/systemd-networkd-wait-online \
        "$systemdnetwork"/80-6rd-tunnel.network \
        "$systemdnetwork"/80-container-host0.network \
        "$systemdnetwork"/80-container-vb.network \
        "$systemdnetwork"/80-container-ve.network \
        "$systemdnetwork"/80-container-vz.network \
        "$systemdnetwork"/80-vm-vt.network \
        "$systemdnetwork"/80-wifi-adhoc.network \
        "$systemdnetwork"/98-default-mac-none.link \
        "$systemdnetwork"/99-default.link \
        "$systemdsystemunitdir"/systemd-networkd.service \
        "$systemdsystemunitdir"/systemd-networkd.socket \
        "$systemdsystemunitdir"/systemd-network-generator.service \
        "$systemdsystemunitdir"/systemd-networkd-wait-online.service \
        "$systemdsystemunitdir"/systemd-networkd-wait-online@.service \
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
            "$systemdnetworkconfdir/*" \
            "$systemdsystemconfdir"/systemd-networkd.service \
            "$systemdsystemconfdir/systemd-networkd.service.d/*.conf" \
            "$systemdsystemconfdir"/systemd-networkd.socket \
            "$systemdsystemconfdir/systemd-networkd.socket.d/*.conf" \
            "$systemdsystemconfdir"/systemd-network-generator.service \
            "$systemdsystemconfdir/systemd-network-generator.service.d/*.conf" \
            "$systemdsystemconfdir"/systemd-networkd-wait-online.service \
            "$systemdsystemconfdir/systemd-networkd-wait-online.service.d/*.conf" \
            "$systemdsystemconfdir"/systemd-networkd-wait-online@.service \
            "$systemdsystemconfdir/systemd-networkd-wait-online@.service.d/*.conf" \
            "$sysusersconfdir"/systemd-network.conf
    fi
}
