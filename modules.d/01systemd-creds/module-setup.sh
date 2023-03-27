#!/bin/bash
# This file is part of dracut.
# SPDX-License-Identifier: GPL-2.0-or-later

# Prerequisite check(s) for module.
check() {

    # If the binary(s) requirements are not fulfilled the module can't be installed.
    require_binaries systemd-creds || return 1

    # Return 255 to only include the module, if another module requires it.
    return 255

}

# Module dependency requirements.
depends() {
    local deps

    # This module has external dependency on other module(s).
    deps="systemd"
    systemd-creds -q has-tpm2 && deps+=" tpm2-tss"
    echo "$deps"

    # Return 0 to include the dependent module(s) in the initramfs.
    return 0

}

# Install the required file(s) and directories for the module in the initramfs.
install() {

    inst_multiple -o \
        "/usr/lib/credstore/*" \
        "/usr/lib/credstore.encrypted/*" \
        "$tmpfilesdir/credstore.conf" \
        systemd-creds

    # Install the hosts local user configurations if enabled.
    if [[ $hostonly ]]; then
        inst_multiple -H -o \
            "/etc/credstore/*" \
            "/etc/credstore.encrypted/*"
    fi

}
