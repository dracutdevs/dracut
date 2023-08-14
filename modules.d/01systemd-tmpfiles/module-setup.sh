#!/bin/bash
# This file is part of dracut.
# SPDX-License-Identifier: GPL-2.0-or-later

# Prerequisite check(s) for module.
check() {

    # If the binary(s) requirements are not fulfilled the module can't be installed.
    require_binaries systemd-tmpfiles || return 1

    # Return 255 to only include the module, if another module requires it.
    return 255

}

# Module dependency requirements.
depends() {

    # Return 0 to include the dependent module(s) in the initramfs.
    return 0

}

# Install the required file(s) and directories for the module in the initramfs.
install() {

    # Excluding "$tmpfilesdir/home.conf", sets up /home /srv
    # Excluding "$tmpfilesdir/journal-nocow.conf", requires spesific btrfs setup
    # Excluding "$tmpfilesdir/legacy.conf", belongs in seperated legacy module
    # Excluding "$tmpfilesdir/systemd-nologin.conf", belongs in seperated pam module
    # Excluding "$tmpfilesdir/systemd-nspawn.conf", belongs in seperated machined module
    # Excluding "$tmpfilesdir/x11.conf", belongs in seperated x11 module

    inst_multiple -o \
        /usr/lib/group \
        /usr/lib/passwd \
        "$tmpfilesdir/etc.conf" \
        "$tmpfilesdir/static-nodes-permissions.conf" \
        "$tmpfilesdir/systemd-tmp.conf" \
        "$tmpfilesdir/systemd.conf" \
        "$tmpfilesdir/var.conf" \
        "$systemdsystemunitdir"/systemd-tmpfiles-clean.service \
        "$systemdsystemunitdir/systemd-tmpfiles-clean.service.d/*.conf" \
        "$systemdsystemunitdir"/systemd-tmpfiles-setup.service \
        "$systemdsystemunitdir/systemd-tmpfiles-setup.service.d/*.conf" \
        "$systemdsystemunitdir"/systemd-tmpfiles-setup-dev.service \
        "$systemdsystemunitdir/systemd-tmpfiles-setup-dev.service.d/*.conf" \
        "$systemdsystemunitdir"/systemd-tmpfiles-setup-dev-early.service \
        "$systemdsystemunitdir/systemd-tmpfiles-setup-dev-early.service.d/*.conf" \
        "$systemdsystemunitdir"/sysinit.target.wants/systemd-tmpfiles-setup.service \
        "$systemdsystemunitdir"/sysinit.target.wants/systemd-tmpfiles-setup-dev.service \
        "$systemdsystemunitdir"/sysinit.target.wants/systemd-tmpfiles-setup-dev-early.service \
        systemd-tmpfiles

    # Install the hosts local user configurations if enabled.
    if [[ $hostonly ]]; then
        inst_multiple -H -o \
            /etc/group \
            /etc/passwd \
            "$tmpfilesconfdir/*.conf" \
            "$systemdsystemconfdir"/systemd-tmpfiles-clean.service \
            "$systemdsystemconfdir/systemd-tmpfiles-clean.service.d/*.conf" \
            "$systemdsystemconfdir"/systemd-tmpfiles-setup.service \
            "$systemdsystemconfdir/systemd-tmpfiles-setup.service.d/*.conf" \
            "$systemdsystemconfdir"/systemd-tmpfiles-setup-dev.service \
            "$systemdsystemconfdir/systemd-tmpfiles-setup-dev.service.d/*.conf" \
            "$systemdsystemconfdir"/systemd-tmpfiles-setup-dev-early.service \
            "$systemdsystemconfdir/systemd-tmpfiles-setup-dev-early.service.d/*.conf"
    fi

}
