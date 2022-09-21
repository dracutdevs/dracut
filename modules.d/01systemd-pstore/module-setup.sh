#!/bin/bash
# This file is part of dracut.
# SPDX-License-Identifier: GPL-2.0-or-later

# Prerequisite check(s) for module.
check() {

    # If the binary(s) requirements are not fulfilled the module can't be installed.
    require_binaries "$systemdutildir"/systemd-pstore || return 1

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

# Install kernel module(s).
installkernel() {
    instmods efi-pstore
}

# Install the required file(s) and directories for the module in the initramfs.
install() {

    inst_dir /var/lib/systemd/pstore
    inst_multiple -o \
        "$tmpfilesdir/systemd-pstore.conf" \
        "$systemdutildir"/systemd-pstore \
        "$systemdsystemunitdir"/systemd-pstore.service \
        "$systemdsystemunitdir/systemd-pstore.service.d/*.conf"

    # Enable systemd type unit(s)
    $SYSTEMCTL -q --root "$initdir" enable systemd-pstore.service

    # Install the hosts local user configurations if enabled.
    if [[ $hostonly ]]; then
        inst_multiple -H -o \
            "$systemdutilconfdir"/pstore.conf \
            "$systemdutilconfdir/pstore.conf.d/*.conf" \
            "$systemdsystemconfdir"/systemd-pstore.service \
            "$systemdsystemconfdir/systemd-pstore.service.d/*.conf"
    fi

}
