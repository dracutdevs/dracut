#!/bin/bash
# This file is part of dracut.
# SPDX-License-Identifier: GPL-2.0-or-later

# Prerequisite check(s) for module.
check() {

    # If the binary(s) requirements are not fulfilled the module can't be installed.
    require_binaries \
        portablectl \
        "$systemdutildir"/systemd-portabled \
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

# Install kernel module(s).
installkernel() {
    instmods loop squashfs
}

# Install the required file(s) and directories for the module in the initramfs.
install() {

    # It's intended to work only with raw binary disk images contained in
    # regular files, but not with directory trees.
    local _nonraw
    _nonraw=$(portablectl --no-pager --no-legend list | grep -v " raw " | cut -d ' ' -f1 | tr '\n' ' ')
    if [ -n "$_nonraw" ]; then
        dwarn "systemd-portabled: this module only installs raw disk images in the initramfs; skipping: $_nonraw"
    fi

    inst_multiple -o \
        "/var/lib/portables/*.raw" \
        "/usr/lib/portables/*.raw" \
        "$tmpfilesdir/portables.conf" \
        "$dbussystem"/org.freedesktop.portable1.conf \
        "$dbussystemservices"/org.freedesktop.portable1.service \
        "$systemdutildir"/systemd-portabled \
        "$systemdutildir/portable/profile/default/*.conf" \
        "$systemdutildir/portable/profile/nonetwork/*.conf" \
        "$systemdutildir/portable/profile/strict/*.conf" \
        "$systemdutildir/portable/profile/trusted/*.conf" \
        "$systemdsystemunitdir"/systemd-portabled.service \
        "$systemdsystemunitdir/systemd-portabled.service.d/*.conf" \
        "$systemdsystemunitdir"/dbus-org.freedesktop.portable1.service \
        portablectl

    # The existence of this file is required
    touch "$initdir"/etc/resolv.conf

    # Enable systemd type unit(s)
    $SYSTEMCTL -q --root "$initdir" add-wants initrd.target systemd-portabled.service
    $SYSTEMCTL -q --root "$initdir" enable systemd-portabled.service

    # Install the hosts local user configurations if enabled.
    if [[ $hostonly ]]; then
        inst_multiple -H -o \
            "/etc/portables/*.raw" \
            "$systemdutilconfdir/system.attached/*" \
            "$systemdutilconfdir/system.attached/*/*" \
            "$systemdutilconfdir/portable/profile/default/*.conf" \
            "$systemdutilconfdir/portable/profile/nonetwork/*.conf" \
            "$systemdutilconfdir/portable/profile/strict/*.conf" \
            "$systemdutilconfdir/portable/profile/trusted/*.conf" \
            "$systemdsystemconfdir"/systemd-portabled.service \
            "$systemdsystemconfdir/systemd-portabled.service.d/*.conf"
    fi

}
