#!/bin/bash
# This file is part of dracut.
# SPDX-License-Identifier: GPL-2.0-or-later

# Prerequisite check(s) for module.
check() {

    # If the binary(s) requirements are not fulfilled the module can't be installed.
    require_binaries ldconfig || return 1

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
        /etc/ld.so.cache \
        /etc/ld.so.conf \
        "/etc/ld.so.conf.d/*.conf" \
        "$systemdsystemunitdir"/ldconfig.service \
        "$systemdsystemunitdir/ldconfig.service.d/*.conf" \
        "$systemdsystemunitdir"/sysinit.target.wants/ldconfig.service \
        ldconfig

    # Install required libraries.
    _arch=${DRACUT_ARCH:-$(uname -m)}
    inst_libdir_file {"tls/$_arch/",tls/,"$_arch/",}"ld.so"

    # Install the hosts local user configurations if enabled.
    if [[ $hostonly ]]; then
        inst_multiple -H -o \
            "$systemdsystemconfdir"/ldconfig.service \
            "$systemdsystemconfdir/ldconfig.service.d/*.conf"
    fi

}
