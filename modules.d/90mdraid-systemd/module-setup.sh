#!/bin/bash
# This file is part of dracut.
# SPDX-License-Identifier: GPL-2.0-or-later

# Prerequisite check(s) for module.
check() {

    # If the binary(s) requirements are not fulfilled the module can't be installed.
    require_binaries \
        basename \
        blkid \
        mdadm \
        readlink \
        || return 1

    # Return 255 to only include the module, if another module requires it.
    return 255

}

# Module dependency requirements.
depends() {

    # This module has external dependency on other module(s).
    echo rootfs-block systemd-udevd
    # Return 0 to include the dependent module(s) in the initramfs.
    return 0

}

# Install kernel module(s).
installkernel() {
    instmods '=drivers/md'
}

# Install the required file(s) and directories for the module in the initramfs.
install() {

    inst_multiple -o \
        /usr/libexec/mdadm/mdadm_env.sh \
        "$tmpfilesdir"/mdadm.conf \
        "$udevrulesdir"/01-md-raid-creating.rules \
        "$udevrulesdir"/63-md-raid-arrays.rules \
        "$udevrulesdir"/64-md-raid-assembly.rules \
        "$udevrulesdir"/65-md-incremental.rules \
        "$udevrulesdir"/69-md-clustered-confirm-device.rules \
        "$systemdsystemunitdir"/mdadm-grow-continue@.service \
        "$systemdsystemunitdir"/mdadm-last-resort@.service \
        "$systemdsystemunitdir"/mdadm-last-resort@.timer \
        "$systemdsystemunitdir"/system-shutdown/mdadm.shutdown \
        "$systemdsystemunitdir"/mdcheck_continue.service \
        "$systemdsystemunitdir"/mdcheck_continue.timer \
        "$systemdsystemunitdir"/mdcheck_start.service \
        "$systemdsystemunitdir"/mdcheck_start.timer \
        "$systemdsystemunitdir"/mdmon@.service \
        "$systemdsystemunitdir"/mdmonitor.service \
        "$systemdsystemunitdir"/mdmonitor-oneshot.service \
        "$systemdsystemunitdir"/mdmonitor-oneshot.timer \
        basename blkid mdadm readlink

    # Install the hosts local user configurations if enabled.
    if [[ $hostonly ]]; then
        inst_multiple -H -o \
            /etc/mdadm.conf \
            "/etc/mdadm.conf.d/*.conf" \
            "$systemdsystemconfdir"/mdadm-grow-continue@.service \
            "$systemdsystemconfdir/mdadm-grow-continue@.service.d/*.conf" \
            "$systemdsystemconfdir"/mdmon@.service \
            "$systemdsystemconfdir/mdmon@.service.d/*.conf" \
            "$systemdsystemconfdir"/mdmonitor.service \
            "$systemdsystemconfdir/mdmonitor.service/*.target"
    fi

    # Install required libraries.
    _arch=${DRACUT_ARCH:-$(uname -m)}
    inst_libdir_file {"tls/$_arch/",tls/,"$_arch/",}"libdlm.so.*"

}
