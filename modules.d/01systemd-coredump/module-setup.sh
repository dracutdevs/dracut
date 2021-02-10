#!/bin/sh
# This file is part of dracut.
# SPDX-License-Identifier: GPL-2.0-or-later

# Prerequisite check(s) for module.
check() {

    # If the binary(s) requirements are not fulfilled
    # return 1 to not include the binary.
    require_binaries coredumpctl || return 1
    require_binaries $systemdutildir/systemd-coredump || return 1

    # If the module dependency requirements are not fulfilled
    # return 1 to not include the required module(s).
    if ! dracut_module_included "systemd"; then
        derror "systemd-coredump needs systemd in the initramfs."
        return 1
    fi

    if ! dracut_module_included "systemd-journald"; then
         derror "systemd-coredump needs systemd-journald in the initramfs."
         return 1
    fi

    if ! dracut_module_included "systemd-sysctl"; then
        derror "systemd-coredump needs systemd-sysctl in the initramfs."
        return 1
    fi

    # Return 255 to only include the module, if another module requires it.
    return 255

}

# Module dependency requirements.
depends() {

    # This module has external dependency on the systemd module.
    echo systemd systemd-journald systemd-sysctl
    # Return 0 to include the dependent systemd module in the initramfs.
    return 0

}

# Install the required file(s) for the module in the initramfs.
install() {

    # Install the required directories.
    inst_dir   /var/lib/systemd/coredump
    # Install the required file(s.
    # Install the kernel configuration parameters for coredump.
    # Install vendor configuration files.
    # Install the systemd type service unit for coredump.
    # Install the binary executable(s) for sysusers.
    inst_multiple -o \
        $sysctld/50-coredump.conf \
        $systemdutildir/coredump.conf \
        $systemdsystemunitdir/systemd-coredump \
        $systemdsystemunitdir/systemd-coredump.socket \
        $systemdsystemunitdir/systemd-coredump@.service\
        $systemdsystemunitdir/sockets.target.wants/systemd-coredump.socket \
        coredumpctl

    # Install the hosts local user configurations if enabled.
    if [[ $hostonly ]]; then
        inst_multiple -H -o \
            $systemdutilconfdir/coredump.conf \
            $systemdsystemconfdir/coredump.conf.d/*.conf \
            $systemdsystemconfdir/systemd-coredump.socket \
            $systemdsystemconfdir/systemd-coredump.socket.d/*.conf \
            $systemdsystemconfdir/systemd-coredump@.service \
            $systemdsystemconfdir/systemd-coredump@.service.d/*.conf \
            $systemdsystemconfdir/sockets.target.wants/systemd-coredump.socket \
            ${NULL}
    fi
}
