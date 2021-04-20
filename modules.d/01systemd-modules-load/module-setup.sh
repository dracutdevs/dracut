#!/bin/bash
# This file is part of dracut.
# SPDX-License-Identifier: GPL-2.0-or-later

# Prerequisite check(s) for module.
check() {

    # If the binary(s) requirements are not fulfilled the module can't be installed
    require_binaries "$systemdutildir"/systemd-modules-load || return 1

    # Return 255 to only include the module, if another module requires it.
    return 255

}

# Module dependency requirements.
depends() {

    # Return 0 to include the dependent module(s) in the initramfs.
    return 0

}

# Install the required file(s) and directories for the module in the initramfs.
install() {

    inst_multiple -o \
        "$modulesload/*.conf" \
        "$systemdutildir"/systemd-modules-load \
        "$systemdsystemunitdir"/systemd-modules-load.service \
        "$systemdsystemunitdir"/sysinit.target.wants/systemd-modules-load.service

    # Enable systemd type unit(s)
    $SYSTEMCTL -q --root "$initdir" enable systemd-modules-load.service

    # Install the hosts local user configurations if enabled.
    if [[ $hostonly ]]; then
        inst_multiple -H -o \
            "$modulesloadconfdir/*.conf" \
            "$systemdsystemconfdir"/systemd-modules-load.service \
            "$systemdsystemconfdir/systemd-modules-load.service.d/*.conf"
    fi

}
