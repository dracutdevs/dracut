#!/bin/bash
# This file is part of dracut.
# SPDX-License-Identifier: GPL-2.0-or-later

# Prerequisite check(s) for module.
check() {

    # If the binary(s) requirements are not fulfilled the module can't be installed.
    require_binaries "$systemdutildir"/systemd-rfkill || return 1

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
        "$systemdutildir"/systemd-rfkill \
        "$systemdsystemunitdir"/systemd-rfkill.service \
        "$systemdsystemunitdir"/systemd-rfkill.socket

    # Install the hosts local user configurations if enabled.
    if [[ $hostonly ]]; then
        inst_multiple -H -o \
            "$systemdsystemconfdir"/systemd-rfkill.service \
            "$systemdsystemconfdir/systemd-rfkill.service.d/*.conf" \
            "$systemdsystemconfdir"/systemd-rfkill.socket \
            "$systemdsystemconfdir/systemd-rfkill.socket.d/*.conf"
    fi

}
