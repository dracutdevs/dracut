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
        "$udevdir"/hwdb.bin \
        "$udevdir"/udev.conf \
        "$udevdir"/ata_id \
        "$udevdir"/cdrom_id \
        "$udevdir"/dmi_memory_id \
        "$udevdir"/fido_id \
        "$udevdir"/mtd_probe \
        "$udevdir"/mtp-probe \
        "$udevdir"/scsi_id \
        "$udevdir"/v4l_id \
        "$udevrulesdir"/50-udev-default.rules \
        "$udevrulesdir"/60-autosuspend.rules \
        "$udevrulesdir"/60-block.rules \
        "$udevrulesdir"/60-cdrom_id.rules \
        "$udevrulesdir"/60-drm.rules \
        "$udevrulesdir"/60-evdev.rules \
        "$udevrulesdir"/60-fido-id.rules \
        "$udevrulesdir"/60-input-id.rules \
        "$udevrulesdir"/60-persistent-alsa.rules \
        "$udevrulesdir"/60-persistent-input.rules \
        "$udevrulesdir"/60-persistent-storage-tape.rules \
        "$udevrulesdir"/60-persistent-storage.rules \
        "$udevrulesdir"/60-persistent-v4l.rules \
        "$udevrulesdir"/60-sensor.rules \
        "$udevrulesdir"/60-serial.rules \
        "$udevrulesdir"/64-btrfs.rules \
        "$udevrulesdir"/70-joystick.rules \
        "$udevrulesdir"/70-memory.rules \
        "$udevrulesdir"/70-mouse.rules \
        "$udevrulesdir"/70-touchpad.rules \
        "$udevrulesdir"/75-net-description.rules \
        "$udevrulesdir"/75-probe_mtd.rules \
        "$udevrulesdir"/78-sound-card.rules \
        "$udevrulesdir"/80-drivers.rules \
        "$udevrulesdir"/80-net-setup-link.rules \
        "$udevrulesdir"/81-net-dhcp.rules \
        "$udevrulesdir"/99-systemd.rules \
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
            "$udevconfdir"/hwdb.bin \
            "$udevconfdir"/udev.conf \
            "$udevrulesconfdir/*.rules" \
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
