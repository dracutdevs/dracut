#!/bin/sh
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
    for _lib in "libfido2.so.*" \
        "libcryptsetup.so.*" \
        "/cryptsetup/libcryptsetup-token-systemd-fido2.so" \
        "libcbor.so.*" \
        "libhidapi-hidraw.so.*"; do
        inst_libdir_file \
            "tls/$_arch/$_lib" \
            "tls/$_lib" \
            "$_arch/$_lib" \
            "$_lib"
    done
}
