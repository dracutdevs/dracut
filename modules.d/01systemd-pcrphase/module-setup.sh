#!/bin/bash
# This file is part of dracut.
# SPDX-License-Identifier: GPL-2.0-or-later

# Prerequisite check(s) for module.
check() {

    # If the binary(s) requirements are not fulfilled the module can't be installed.
    require_binaries "$systemdutildir"/systemd-pcrextend || return 1

    # Return 255 to only include the module, if another module requires it.
    return 255

}

# Module dependency requirements.
depends() {

    # This module has external dependency on other module(s).
    echo systemd tpm2-tss
    # Return 0 to include the dependent module(s) in the initramfs.
    return 0

}

# Install the required file(s) and directories for the module in the initramfs.
install() {

    inst_multiple -o \
        "$systemdutildir"/systemd-pcrextend \
        "$systemdsystemunitdir"/systemd-pcrphase-initrd.service \
        "$systemdsystemunitdir/systemd-pcrphase-initrd.service.d/*.conf" \
        "$systemdsystemunitdir"/initrd.target.wants/systemd-pcrphase-initrd.service

    # Install the hosts local user configurations if enabled.
    if [[ $hostonly ]]; then
        inst_multiple -H -o \
            "$systemdsystemconfdir"/systemd-pcrphase-initrd.service \
            "$systemdsystemconfdir/systemd-pcrphase-initrd.service.d/*.conf" \
            "$systemdsystemconfdir"/initrd.target.wants/systemd-pcrphase-initrd.service
    fi

}
