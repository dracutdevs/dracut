#!/bin/bash
# This file is part of dracut.
# SPDX-License-Identifier: GPL-2.0-or-later

# Prerequisite check(s) for module.
check() {

    # If the binary(s) requirements are not fulfilled the module can't be installed.
    require_binaries tpm2 || return 1

    # Return 255 to only include the module, if another module requires it.
    return 255

}

# Module dependency requirements.
depends() {

    # This module has external dependency on other module(s).
    echo systemd-sysusers systemd-udevd
    # Return 0 to include the dependent module(s) in the initramfs.
    return 0

}

# Install kernel module(s).
installkernel() {
    instmods '=drivers/char/tpm'
}

# Install the required file(s) and directories for the module in the initramfs.
install() {

    inst_multiple -o \
        "$sysusers"/tpm2-tss.conf \
        "$tmpfilesdir"/tpm2-tss-fapi.conf \
        "$udevrulesdir"/60-tpm-udev.rules \
        "$systemdutildir"/system-generators/systemd-tpm2-generator \
        "$systemdsystemunitdir/tpm2.target" \
        tpm2_pcrread tpm2_pcrextend tpm2_createprimary tpm2_createpolicy \
        tpm2_create tpm2_load tpm2_unseal tpm2

    # Install library file(s)
    _arch=${DRACUT_ARCH:-$(uname -m)}
    inst_libdir_file \
        {"tls/$_arch/",tls/,"$_arch/",}"libtss2-esys.so.*" \
        {"tls/$_arch/",tls/,"$_arch/",}"libtss2-fapi.so.*" \
        {"tls/$_arch/",tls/,"$_arch/",}"libtss2-mu.so.*" \
        {"tls/$_arch/",tls/,"$_arch/",}"libtss2-rc.so.*" \
        {"tls/$_arch/",tls/,"$_arch/",}"libtss2-sys.so.*" \
        {"tls/$_arch/",tls/,"$_arch/",}"libtss2-tcti-cmd.so.*" \
        {"tls/$_arch/",tls/,"$_arch/",}"libtss2-tcti-device.so.*" \
        {"tls/$_arch/",tls/,"$_arch/",}"libtss2-tcti-mssim.so.*" \
        {"tls/$_arch/",tls/,"$_arch/",}"libtss2-tcti-swtpm.so.*" \
        {"tls/$_arch/",tls/,"$_arch/",}"libtss2-tctildr.so.*" \
        {"tls/$_arch/",tls/,"$_arch/",}"libcryptsetup.so.*" \
        {"tls/$_arch/",tls/,"$_arch/",}"/cryptsetup/libcryptsetup-token-systemd-tpm2.so" \
        {"tls/$_arch/",tls/,"$_arch/",}"libcurl.so.*" \
        {"tls/$_arch/",tls/,"$_arch/",}"libjson-c.so.*"

}
