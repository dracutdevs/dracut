#!/bin/bash
# This file is part of dracut.
# SPDX-License-Identifier: GPL-2.0-or-later

# Prerequisite check(s) for module.
check() {

    # If the binary(s) requirements are not fulfilled the module can't be installed
    require_binaries busctl || return 1
    require_binaries dbus-daemon || return 1
    require_binaries dbus-send || return 1

    # Return 255 to only include the module, if another module requires it.
    return 255
}

# Module dependency requirements.
depends() {

    # This module has external dependency on the systemd module.
    echo systemd
    # Return 0 to include the dependent systemd module in the initramfs.
    return 0
}

# Install the required file(s) and directories for the module in the initramfs.
install() {
    # dbus conflicts with dbus-broker.
    if dracut_module_included "dbus-broker"; then
        derror "dbus conflicts with dbus-broker in the initramfs."
        return 1
    fi

    # Create dbus related directories.
    inst_dir "$dbus"
    inst_dir "$dbusinterfaces"
    inst_dir "$dbusservices"
    inst_dir "$dbussession"
    inst_dir "$dbussystem"
    inst_dir "$dbussystemservices"
    inst_dir "$dbusconfdir"
    inst_dir "$dbusinterfacesconfdir"
    inst_dir "$dbusservicesconfdir"
    inst_dir "$dbussessionconfdir"
    inst_dir "$dbussystemconfdir"
    inst_dir "$dbussystemservicesconfdir"

    inst_multiple -o \
        "$dbus"/system.conf \
        "$dbussystem"/org.freedesktop.systemd1.conf \
        "$dbusservicesconfdir"/org.freedesktop.systemd1.service \
        "$dbussystemservices"/org.freedesktop.systemd1.service \
        "$systemdsystemunitdir"/dbus.target.wants \
        busctl dbus-send dbus-daemon

    # Install custom units
    inst_simple "$moddir"/dbus.service "$systemdsystemunitdir"/dbus.service
    inst_simple "$moddir"/dbus.socket "$systemdsystemunitdir"/dbus.socket
    [[ -e "$initdir$systemdsystemunitdir/systemd-tmpfiles-setup.service" ]] \
        && rm -f "$initdir$systemdsystemunitdir/systemd-tmpfiles-setup.service"
    [[ -e "$initdir$systemdsystemconfdir/systemd-tmpfiles-setup.service" ]] \
        && rm -f "$initdir$systemdsystemconfdir/systemd-tmpfiles-setup.service"
    [[ -d "$initdir$systemdsystemconfdir/systemd-tmpfiles-setup.service.d" ]] \
        && rm -rf "$initdir$systemdsystemconfdir/systemd-tmpfiles-setup.service.d"
    inst_simple "$moddir"/systemd-tmpfiles-setup.service "$systemdsystemunitdir"/systemd-tmpfiles-setup.service

    # Adding the user and group for dbus
    grep '^\(d\|message\)bus:' "$dracutsysrootdir"/etc/passwd >> "$initdir/etc/passwd"
    grep '^\(d\|message\)bus:' "$dracutsysrootdir"/etc/group >> "$initdir/etc/group"

    # Install the hosts local user configurations if enabled.
    if [[ $hostonly ]]; then
        inst_multiple -H -o \
            "$dbusconfdir"/system.conf
    fi

}
