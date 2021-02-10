#!/bin/sh
# This file is part of dracut.
# SPDX-License-Identifier: GPL-2.0-or-later

# Prerequisite check(s) for module.
check() {

    # If the binary(s) requirements are not fulfilled
    # return 1 to not include the binary.
    require_binaries systemd-repart || return 1

    # If the module dependency requirements are not fulfilled
    # return 1 to not include the required module(s).
    if ! dracut_module_included "systemd"; then
        derror "systemd-repart needs systemd in the initramfs."
        return 1
    fi

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

    # Install vendor repartition configurations
    # Install the systemd type service unit for systemd repart.
    # Install the binary executable(s) for systemd repart
    inst_multiple -o \
        $libdir/repart.d/*.conf \
        $systemdsystemunitdir/systemd-repart.service \
        $systemdsystemunitdir/initrd-root-fs.target.wants/systemd-repart.service \
        systemd-repart

    # Install the hosts local user configurations if enabled.
    if [[ $hostonly ]]; then
        inst_multiple -H -o \
            /etc/repart.d/*.conf \
            $systemdsystemconfdir/systemd-repart.service \
            $systemdsystemconfdir/systemd-repart.service.d/*.conf \
            ${NULL}
    fi
}
