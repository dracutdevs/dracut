#!/bin/bash
# This file is part of dracut.
# SPDX-License-Identifier: GPL-2.0-or-later

# Prerequisite check(s) for module.
check() {

    # If the binary(s) requirements are not fulfilled the module can't be installed.
    require_binaries systemd-repart || return 1

    # Return 255 to only include the module, if another module requires it.
    return 255

}

# Module dependency requirements.
depends() {

    # Return 0 to include the dependent module(s) in the initramfs.
    return 0

}

# Install the required file(s) for the module in the initramfs.
install() {

    inst_multiple -o \
        "/usr/lib/repart.d/*.conf" \
        "$systemdsystemunitdir"/systemd-repart.service \
        "$systemdsystemunitdir"/initrd-root-fs.target.wants/systemd-repart.service \
        systemd-repart

    # Install the hosts local user configurations if enabled.
    if [[ $hostonly ]]; then
        inst_multiple -H -o \
            "/etc/repart.d/*.conf" \
            "$systemdsystemconfdir"/systemd-repart.service \
            "$systemdsystemconfdir/systemd-repart.service.d/*.conf"
    fi
}
