#!/bin/sh
# This file is part of dracut.
# SPDX-License-Identifier: GPL-2.0-or-later

# Prerequisite check(s) for module.
check() {

    # If the binary(s) requirements are not fulfilled the module can't be installed
    require_binaries busctl || return 1
    require_binaries dbus-daemon || return 1
    require_binaries dbus-send || return 1

    # dbus conflicts with dbus-broker.
    if dracut_module_included "dbus-broker"; then
        derror "dbus conflicts with dbus-broker in the initramfs."
        exit 1
    fi

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

    # Create dbus related directories.
    inst_dir $dbus
    inst_dir $dbusinterfaces
    inst_dir $dbusservices
    inst_dir $dbussession
    inst_dir $dbussystem
    inst_dir $dbussystemservices
    inst_dir $dbusconfdir
    inst_dir $dbusinterfacesconfdir
    inst_dir $dbusservicesconfdir
    inst_dir $dbussessionconfdir
    inst_dir $dbussystemconfdir
    inst_dir $dbussystemservicesconfdir

    inst_multiple -o \
        $dbus/system.conf \
        $dbussystem/org.freedesktop.systemd1.conf \
        $dbusservicesconfdir/org.freedesktop.systemd1.service \
        $dbussystemservices/org.freedesktop.systemd1.service \
        $systemdsystemunitdir/dbus.service \
        $systemdsystemunitdir/dbus.socket \
        $systemdsystemunitdir/dbus.target.wants \
        busctl dbus-send dbus-daemon

    # Adjusting dependencies for initramfs in the dbus service unit.
    sed -i -e \
        '/^\[Unit\]/aDefaultDependencies=no\
        Conflicts=shutdown.target\
        Before=shutdown.target' \
        "$initdir$systemdsystemunitdir/dbus.service"

    # Adjusting dependencies for initramfs in the dbus socket unit.
    sed -i -e \
       '/^\[Unit\]/aDefaultDependencies=no\
        Conflicts=shutdown.target\
        Before=shutdown.target
        /^\[Socket\]/aRemoveOnStop=yes' \
        "$initdir$systemdsystemunitdir/dbus.socket"

    # Adding the user and group for dbus
    grep '^\(d\|message\)bus:' "$dracutsysrootdir"/etc/passwd >> "$initdir/etc/passwd"
    grep '^\(d\|message\)bus:' "$dracutsysrootdir"/etc/group >> "$initdir/etc/group"

    # Install the hosts local user configurations if enabled.
    if [[ $hostonly ]]; then
        inst_multiple -H -o \
            $dbusconfdir/system.conf \
            $systemdsystemconfdir/dbus.socket \
            $systemdsystemconfdir/dbus.socket.d/*.conf \
            $systemdsystemconfdir/dbus.service \
            $systemdsystemconfdir/dbus.service.d/*.conf \
            ${NULL}
     fi

    # We need to make sure that systemd-tmpfiles-setup.service->dbus.socket
    # will not wait for local-fs.target to start if swap is encrypted,
    # this would make dbus wait the timeout for the swap before loading.
    # This could delay sysinit services that are dependent on dbus.service.
    sed -i -Ee \
        '/^After/s/(After[[:space:]]*=.*)(local-fs.target[[:space:]]*)(.*)/\1-\.mount \3/' \
        "$initdir$systemdsystemunitdir/systemd-tmpfiles-setup.service"
}
