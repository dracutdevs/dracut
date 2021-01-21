#!/bin/sh
# This file is part of dracut.
# SPDX-License-Identifier: GPL-2.0-or-later

# Prerequisite check(s) for module.
check() {

    # If the binary(s) requirements are not fulfilled the module can't be installed
    require_binaries $systemdutildir/systemd-modules-load || return 1

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

# Install the required file(s) for the module in the initramfs.
install() {

        # Create systemd-modules-load related directories.
        inst_dir    $modulesload
        inst_dir    $modulesloadconfdir

        # Install related files for systemd-modules-load
        inst_multiple -o \
            $systemdsystemunitdir/systemd-modules-load.service \
            $systemdutildir/systemd-modules-load

        # Install local user configurations if host only is enabled..
        if [[ $hostonly ]]; then
            inst_multiple -H -o \
            $systemdsystemconfdir/systemd-modules-load.service \
            $systemdsystemconfdir/systemd-systemd-modules-load.d/*.conf \
            ${NULL}
        fi

        # Enable the systemd type service unit for systemd-modules-load.
        $SYSTEMCTL -q --root "$initdir" enable systemd-modules-load.service

}
