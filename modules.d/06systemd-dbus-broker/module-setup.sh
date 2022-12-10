#!/bin/bash
# This file is part of dracut.
# SPDX-License-Identifier: GPL-2.0-or-later

# Prerequisite check(s) for module.
check() {

    # If the binary(s) requirements are not fulfilled the module can't be installed
    require_binaries busctl || return 1
    require_binaries dbus-broker || return 1
    require_binaries dbus-broker-launch || return 1

    # Return 255 to only include the module, if another module requires it.
    return 255

}

# Module dependency requirements.
depends() {
    # This module has external dependency on the systemd module.
    echo systemd systemd-sysusers
    # Return 0 to include the dependent systemd module in the initramfs.
    return 0

}

# Install the required file(s) and directories for the module in the initramfs.
install() {

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
        "$dbus"/session.conf \
        "$dbus"/system.conf \
        "$dbussystem"/org.freedesktop.systemd1.conf \
        "$dbusservicesconfdir"/org.freedesktop.systemd1.service \
        "$dbussystemservices"/org.freedesktop.systemd1.service \
        "$sysusers"/dbus.conf \
        "$systemdcatalog"/dbus-broker.catalog \
        "$systemdcatalog"/dbus-broker-launch.catalog \
        "$systemdsystemunitdir"/dbus-broker.service \
        "$systemduser"/dbus-broker.service \
        "$systemdsystemunitdir"/dbus.socket \
        "$systemduser"/dbus.socket \
        "$systemdsystemunitdir"/dbus.target.wants \
        busctl dbus-broker dbus-broker-launch

    # Adjusting dependencies for initramfs in the dbus socket unit.
    # shellcheck disable=SC1004
    sed -i -e \
        '/^\[Unit\]/aDefaultDependencies=no\
        Conflicts=shutdown.target\
        Before=shutdown.target
        /^\[Socket\]/aRemoveOnStop=yes' \
        "$initdir$systemdsystemunitdir/dbus.socket"

    $SYSTEMCTL -q --root "$initdir" enable dbus-broker.service

    # Install the hosts local user configurations if enabled.
    if [[ $hostonly ]]; then
        inst_multiple -H -o \
            "$dbusconfdir"/session.conf \
            "$dbusconfdir"/system.conf \
            "$sysusersconfdir"/dbus.conf \
            "$systemdsystemconfdir"/dbus.socket \
            "$systemdsystemconfdir"/dbus.socket.d/*.conf \
            "$systemdsystemconfdir"/dbus-broker.service \
            "$systemdsystemconfdir"/dbus-broker.service.d/*.conf
    fi

    # We need to make sure that systemd-tmpfiles-setup.service->dbus.socket
    # will not wait for local-fs.target to start if swap is encrypted,
    # this would make dbus wait the timeout for the swap before loading.
    # This could delay sysinit services that are dependent on dbus.service.
    sed -i -Ee \
        '/^After/s/(After[[:space:]]*=.*)(local-fs.target[[:space:]]*)(.*)/\1-\.mount \3/' \
        "$initdir$systemdsystemunitdir/systemd-tmpfiles-setup.service"
}
