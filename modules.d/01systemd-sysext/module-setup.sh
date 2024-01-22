#!/bin/bash
# This file is part of dracut.
# SPDX-License-Identifier: GPL-2.0-or-later

# Prerequisite check(s) for module.
check() {

    # If the binary(s) requirements are not fulfilled the module can't be installed.
    require_binaries systemd-sysext || return 1

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

    # It's intended to work only with raw binary disk images contained in
    # regular files, but not with directory trees.

    inst_multiple -o \
        "/usr/lib/confexts/*.raw" \
        "/var/lib/confexts/*.raw" \
        "/var/lib/extensions/*.raw" \
        "/etc/extension-release.d/extension-release.*" \
        "/usr/lib/extension-release.d/extension-release.*" \
        "$systemdsystemunitdir"/systemd-confext.service \
        "$systemdsystemunitdir/systemd-confext.service.d/*.conf" \
        "$systemdsystemunitdir"/systemd-sysext.service \
        "$systemdsystemunitdir/systemd-sysext.service.d/*.conf" \
        systemd-confext systemd-sysext

    # Enable systemd type unit(s)
    for i in \
        systemd-confext.service \
        systemd-sysext.service; do
        $SYSTEMCTL -q --root "$initdir" enable "$i"
    done

    # Install the hosts local user configurations if enabled.
    if [[ $hostonly ]]; then
        inst_multiple -H -o \
            "/etc/extensions/*.raw" \
            "$systemdsystemconfdir"/systemd-confext.service \
            "$systemdsystemconfdir/systemd-confext.service.d/*.conf" \
            "$systemdsystemconfdir"/systemd-sysext.service \
            "$systemdsystemconfdir/systemd-sysext.service.d/*.conf"
    fi

}
