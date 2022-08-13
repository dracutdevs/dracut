#!/bin/sh
# This file is part of dracut.
# SPDX-License-Identifier: GPL-2.0-or-later

# Prerequisite check(s) for module.
check() {

    # If the binary(s) requirements are not fulfilled the module can't be installed.
    require_binaries pcscd || return 1

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
    inst_simple "$moddir/pcscd.service" "${systemdsystemunitdir}"/pcscd.service
    inst_simple "$moddir/pcscd.socket" "${systemdsystemunitdir}"/pcscd.socket

    inst_multiple -o \
        pcscd

    # Enable systemd type unit(s)
    for i in \
        pcscd.service \
        pcscd.socket; do
        $SYSTEMCTL -q --root "$initdir" enable "$i"
    done

    # Install library file(s)
    _arch=${DRACUT_ARCH:-$(uname -m)}
    for _lib in "libopensc.so.*" \
        "libsmm-local.so.*" \
        "opensc-pkcs11.so" \
        "onepin-opensc-pkcs11.so" \
        "pkcs11/opensc-pkcs11.so" \
        "pkcs11/onepin-opensc-pkcs11.so" \
        "pcsc/drivers/ifd-ccid.bundle/Contents/Info.plist" \
        "pcsc/drivers/ifd-ccid.bundle/Contents/Linux/libccid.so" \
        "pcsc/drivers/serial/libccidtwin.so" \
        "libpcsclite.so.*"; do
        inst_libdir_file \
            "tls/$_arch/$_lib" \
            "tls/$_lib" \
            "$_arch/$_lib" \
            "$_lib"
    done

    # Install the hosts local user configurations if enabled.
    if [ -n "$hostonly" ]; then
        inst_multiple -H -o \
            /etc/opensc.conf \
            "/etc/reader.conf.d/*"
    fi

}
