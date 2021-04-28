#!/bin/bash
# This file is part of dracut.
# SPDX-License-Identifier: GPL-2.0-or-later

# Prerequisite check(s) for module.
check() {

    # If the binary(s) requirements are not fulfilled the module can't be installed.
    require_binaries \
        udevadm \
        "$systemdutildir"/systemd-udevd \
        || return 1

    # Return 255 to only include the module, if another module requires it.
    return 255

}

# Module dependency requirements.
depends() {

    # This module has external dependency on other module(s).
    echo systemd
    # Return 0 to include the dependent module(s) in the initramfs.
    return 0

}

# Install the required file(s) and directories for the module in the initramfs.
install() {

    inst_multiple -o \
        /usr/lib/udev/hwdb.bin \
        /usr/lib/udev/udev.conf \
        /usr/lib/udev/rules.d/50-udev-default.rules \
        /usr/lib/udev/rules.d/60-autosuspend.rules \
        /usr/lib/udev/rules.d/60-block.rules \
        /usr/lib/udev/rules.d/60-cdrom_id.rules \
        /usr/lib/udev/rules.d/60-drm.rules \
        /usr/lib/udev/rules.d/60-evdev.rules \
        /usr/lib/udev/rules.d/60-fido-id.rules \
        /usr/lib/udev/rules.d/60-input-id.rules \
        /usr/lib/udev/rules.d/60-persistent-alsa.rules \
        /usr/lib/udev/rules.d/60-persistent-input.rules \
        /usr/lib/udev/rules.d/60-persistent-storage-tape.rules \
        /usr/lib/udev/rules.d/60-persistent-storage.rules \
        /usr/lib/udev/rules.d/60-persistent-v4l.rules \
        /usr/lib/udev/rules.d/60-sensor.rules \
        /usr/lib/udev/rules.d/60-serial.rules \
        /usr/lib/udev/rules.d/64-btrfs.rules \
        /usr/lib/udev/rules.d/70-joystick.rules \
        /usr/lib/udev/rules.d/70-memory.rules \
        /usr/lib/udev/rules.d/70-mouse.rules \
        /usr/lib/udev/rules.d/70-touchpad.rules \
        /usr/lib/udev/rules.d/75-net-description.rules \
        /usr/lib/udev/rules.d/75-probe_mtd.rules \
        /usr/lib/udev/rules.d/78-sound-card.rules \
        /usr/lib/udev/rules.d/80-drivers.rules \
        /usr/lib/udev/rules.d/80-net-setup-link.rules \
        /usr/lib/udev/rules.d/81-net-dhcp.rules \
        /usr/lib/udev/rules.d/99-systemd.rules \
        "$systemdutildir"/systemd-udevd \
        "$systemdsystemunitdir"/systemd-udevd.service \
        "$systemdsystemunitdir/systemd-udevd.service.d/*.conf" \
        "$systemdsystemunitdir"/systemd-udev-trigger.service \
        "$systemdsystemunitdir/systemd-udev-trigger.service.d/*.conf" \
        "$systemdsystemunitdir"/systemd-udev-settle.service \
        "$systemdsystemunitdir/systemd-udev-settle.service.d/*.conf" \
        "$systemdsystemunitdir"/systemd-udevd-control.socket \
        "$systemdsystemunitdir"/systemd-udevd-kernel.socket \
        "$systemdsystemunitdir"/sockets.target.wants/systemd-udevd-control.socket \
        "$systemdsystemunitdir"/sockets.target.wants/systemd-udevd-kernel.socket \
        "$systemdsystemunitdir"/sysinit.target.wants/systemd-udevd.service \
        "$systemdsystemunitdir"/sysinit.target.wants/systemd-udev-trigger.service \
        udevadm

    # Install the hosts local user configurations if enabled.
    if [[ $hostonly ]]; then
        inst_multiple -H -o \
            /etc/udev/hwdb.bin \
            /etc/udev/udev.conf \
            "/etc/udev/rules.d/*.rules" \
            "$systemdutilconfdir"/hwdb/hwdb.bin \
            "$systemdsystemconfdir"/systemd-udevd.service \
            "$systemdsystemconfdir/systemd-udevd.service.d/*.conf" \
            "$systemdsystemconfdir"/systemd-udev-trigger.service \
            "$systemdsystemconfdir/systemd-udev-trigger.service.d/*.conf" \
            "$systemdsystemconfdir"/systemd-udev-settle.service \
            "$systemdsystemconfdir/systemd-udev-settle.service.d/*.conf" \
            "$systemdsystemconfdir"/systemd-udevd-control.socket \
            "$systemdsystemconfdir"/systemd-udevd-kernel.socket \
            "$systemdsystemconfdir"/sockets.target.wants/systemd-udevd-control.socket \
            "$systemdsystemconfdir"/sockets.target.wants/systemd-udevd-kernel.socket \
            "$systemdsystemconfdir"/sysinit.target.wants/systemd-udevd.service \
            "$systemdsystemconfdir"/sysinit.target.wants/systemd-udev-trigger.service
    fi

    # Install required libraries.
    _arch=${DRACUT_ARCH:-$(uname -m)}
    inst_libdir_file {"tls/$_arch/",tls/,"$_arch/",}"libudev.so.*"

}
