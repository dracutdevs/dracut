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

    # Return 0 to include the dependent module(s) in the initramfs.
    return 0

}

# Install the required file(s) and directories for the module in the initramfs.
install() {

    inst_rules "$moddir/99-initrd-power-targets.rules"
    inst systemd-ac-power
    inst_simple "$moddir/initrd-on-ac-power.target" "$systemdsystemunitdir/initrd-on-ac-power.target"
    inst_simple "$moddir/initrd-on-battery-power.target" "$systemdsystemunitdir/initrd-on-battery-power.target"

}
