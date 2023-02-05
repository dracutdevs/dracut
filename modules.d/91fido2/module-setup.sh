#!/bin/bash
# This file is part of dracut.
# SPDX-License-Identifier: GPL-2.0-or-later

# Prerequisite check(s) for module.
check() {
    # Return 255 to only include the module, if another module requires it.
    return 255
}

# Module dependency requirements.
depends() {
    # This module has external dependency on other module(s).
    echo systemd-udevd
    # Return 0 to include the dependent module(s) in the initramfs.
    return 0
}

# Install the required file(s) and directories for the module in the initramfs.
install() {
    # Install required libraries.
    _arch=${DRACUT_ARCH:-$(uname -m)}
    inst_libdir_file \
        {"tls/$_arch/",tls/,"$_arch/",}"libfido2.so.*" \
        {"tls/$_arch/",tls/,"$_arch/",}"libz.so.*" \
        {"tls/$_arch/",tls/,"$_arch/",}"libcryptsetup.so.*" \
        {"tls/$_arch/",tls/,"$_arch/",}"/cryptsetup/libcryptsetup-token-systemd-fido2.so" \
        {"tls/$_arch/",tls/,"$_arch/",}"libcbor.so.*" \
        {"tls/$_arch/",tls/,"$_arch/",}"libhidapi-hidraw.so.*"
}
