#!/bin/bash
# This file is part of dracut.
# SPDX-License-Identifier: GPL-2.0-or-later

# Prerequisite check(s) for module.
check() {

    # If the binary(s) requirements are not fulfilled the module can't be installed
    require_binaries \
        coredumpctl \
        "$systemdutildir"/systemd-coredump \
        || return 1

    # Return 255 to only include the module, if another module requires it.
    return 255

}

# Module dependency requirements.
depends() {

    # This module has external dependency on the systemd module.
    echo systemd-journald systemd-sysctl systemd-sysusers
    # Return 0 to include the dependent module(s) in the initramfs.
    return 0

}

# Install the required file(s) and directories for the module in the initramfs.
install() {

    inst_dir /var/lib/systemd/coredump
    inst_multiple -o \
        "$sysctld"/50-coredump.conf \
        "$systemdutildir"/coredump.conf \
        "$systemdutildir"/systemd-coredump \
        "$systemdsystemunitdir"/systemd-coredump.socket \
        "$systemdsystemunitdir"/systemd-coredump@.service \
        "$systemdsystemunitdir"/sockets.target.wants/systemd-coredump.socket \
        "$sysusers"/systemd-coredump.conf \
        coredumpctl

    # Install library file(s)
    _arch=${DRACUT_ARCH:-$(uname -m)}
    inst_libdir_file \
        {"tls/$_arch/",tls/,"$_arch/",}"liblz4.so.*" \
        {"tls/$_arch/",tls/,"$_arch/",}"liblzma.so.*" \
        {"tls/$_arch/",tls/,"$_arch/",}"libzstd.so.*"

    # Install the hosts local user configurations if enabled.
    if [[ $hostonly ]]; then
        inst_multiple -H -o \
            "$systemdutilconfdir"/coredump.conf \
            "$systemdsystemconfdir/coredump.conf.d/*.conf" \
            "$systemdsystemconfdir"/systemd-coredump.socket \
            "$systemdsystemconfdir/systemd-coredump.socket.d/*.conf" \
            "$systemdsystemconfdir"/systemd-coredump@.service \
            "$systemdsystemconfdir/systemd-coredump@.service.d/*.conf" \
            "$systemdsystemconfdir"/sockets.target.wants/systemd-coredump.socket \
            "$sysusersconfdir"/systemd-coredump.conf
    fi
}
