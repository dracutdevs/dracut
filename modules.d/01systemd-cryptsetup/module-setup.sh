#!/bin/sh
# This file is part of dracut.
# SPDX-License-Identifier: GPL-2.0-or-later

# Prerequisite check(s) for module.
check() {

    # If the binary(s) requirements are not fulfilled
    # return 1 to not include the binary.
    require_binaries $systemdutildir/systemd-cryptsetup || return 1
    require_binaries $systemdutildir/system-generators/systemd-cryptsetup-generator || return 1

    # If the module dependency requirements are not fulfilled
    # return 1 to not include the required module(s).

    if ! dracut_module_included "crypt"; then
        derror "systemd-cryptsetup needs crypt in the initramfs."
        return 1
    fi

    if ! dracut_module_included "systemd"; then
        derror "systemd-cryptsetup needs systemd in the initramfs."
        return 1
    fi

    if ! dracut_module_included "systemd-ask-password"; then
        derror "systemd-cryptsetup needs systemd-ask-password in the initramfs."
        return 1
    fi

    if ! dracut_module_included "systemd-tmpfiles"; then
        derror "systemd-cryptsetup needs tmpfiles in the initramfs."
        return 1
    fi

    # Return 255 to only include the module, if another module requires it.
    return 255

}

# Module dependency requirements.
depends() {

    # This module has external dependency on the systemd module.
    echo crypt systemd systemd-ask-password systemd-tmpfiles
    # Return 0 to include the dependent systemd module in the initramfs.
    return 0

}

# Install the required file(s) for the module in the initramfs.
install() {

    inst_multiple -o \

        # Install the systemd type service unit for systemd-cryptsetup.
        $tmpfilesdir/cryptsetup.conf \
        $systemdutildir/systemd-cryptsetup \
        $systemdutildir/system-generators/systemd-cryptsetup-generator \
        $systemdsystemunitdir/cryptsetup.target \
        $systemdsystemunitdir/cryptsetup-pre.target \
        $systemdsystemunitdir/remote-cryptsetup.target \
        $systemdsystemunitdir/sysinit.target.wants/cryptsetup.target \
        $systemdsystemunitdir/initrd-root-device.target.wants/remote-cryptsetup.target

        if [[ $hostonly ]]; then
            inst_multiple -H -o \
                /etc/crypttab \
                /etc/cryptsetup-keys.d/*.key \
                $systemdsystemconfdir/cryptsetup.target \
                $systemdsystemconfdir/cryptsetup.target.wants/*.target \
                $systemdsystemconfdir/cryptsetup-pre.target \
                $systemdsystemconfdir/cryptsetup-pre.target.wants/*.target \
                $systemdsystemconfdir/remote-cryptsetup.target \
                $systemdsystemconfdir/remote-cryptsetup.target.wants/*.target \
                $systemdsystemconfdir/sysinit.target.wants/cryptsetup.target \
                $systemdsystemconfdir/sysinit.target.wants/cryptsetup.target.wants/*.target
                $systemdsystemconfdir/initrd-root-device.target.wants/remote-cryptsetup.target
                ${NULL}
         fi

        _arch=${DRACUT_ARCH:-$(uname -m)}
        inst_libdir_file {"tls/$_arch/",tls/,"$_arch/",}"libcryptsetup.so.*" \

}
