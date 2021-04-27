#!/bin/bash
# This file is part of dracut.
# SPDX-License-Identifier: GPL-2.0-or-later

# Prerequisite check(s) for module.
check() {

    # If the binary(s) requirements are not fulfilled the module can't be installed.
    require_binaries \
        "$systemdutildir"/systemd-veritysetup \
        "$systemdutildir"/system-generators/systemd-veritysetup-generator \
        || return 1

    # Return 255 to only include the module, if another module requires it.
    return 255

}

# Module dependency requirements.
depends() {

    # This module has external dependency on other module(s).
    echo systemd dm
    # Return 0 to include the dependent module(s) in the initramfs.
    return 0

}

# Install the required file(s) and directories for the module in the initramfs.
install() {

    inst_multiple -o \
        "$systemdutildir"/systemd-veritysetup \
        "$systemdutildir"/system-generators/systemd-veritysetup-generator \
        "$systemdsystemunitdir"/remote-veritysetup.target \
        "$systemdsystemunitdir"/veritysetup-pre.target \
        "$systemdsystemunitdir"/veritysetup.target \
        "$systemdsystemunitdir"/sysinit.target.wants/veritysetup.target \
        "$systemdsystemunitdir"/initrd-root-device.target.wants/remote-veritysetup.target

    # Install the hosts local user configurations if enabled.
    if [[ $hostonly ]]; then
        inst_multiple -H -o \
            /etc/veritytab \
            "$systemdsystemconfdir"/veritysetup.target \
            "$systemdsystemconfdir/veritysetup.target.wants/*.target" \
            "$systemdsystemconfdir"/veritysetup-pre.target \
            "$systemdsystemconfdir/veritysetup-pre.target.wants/*.target" \
            "$systemdsystemconfdir"/remote-veritysetup.target \
            "$systemdsystemconfdir/remote-veritysetup.target.wants/*.target" \
            "$systemdsystemconfdir"/sysinit.target.wants/veritysetup.target \
            "$systemdsystemconfdir/sysinit.target.wants/veritysetup.target.wants/*.target" \
            "$systemdsystemconfdir"/initrd-root-device.target.wants/remote-veritysetup.target
    fi

    # Install required libraries.
    _arch=${DRACUT_ARCH:-$(uname -m)}
    inst_libdir_file {"tls/$_arch/",tls/,"$_arch/",}"libcryptsetup.so.*"

}
