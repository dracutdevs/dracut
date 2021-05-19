#!/bin/bash
# This file is part of dracut.
# SPDX-License-Identifier: GPL-2.0-or-later

# Prerequisite check(s) for module.
check() {
    # We only want to return 255 since this is a meta module.
    return 255
}

# Module dependency requirements.
depends() {
    local _module
    # Add a lvm meta dependency based on the module in use.
    for _module in lvm-initqueue lvm-systemd; do
        if dracut_module_included "$_module"; then
            echo "$_module"
            return 0
        fi
    done

    if pvscan --help | grep -q checkcomplete; then
        echo "lvm-systemd"
        return 0
    else
        echo "lvm-initqueue"
        return 0
    fi

    return 1
}
