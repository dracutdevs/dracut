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
    echo systemd systemd-hostnamed systemd-networkd systemd-resolved systemd-timedated systemd-timesyncd
    # Return 0 to include the dependent module(s) in the initramfs.
    return 0

}
