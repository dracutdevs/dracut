#!/bin/sh
# This file is part of dracut.
# SPDX-License-Identifier: GPL-2.0-or-later

# Prerequisite check(s) for module.
check() {
    # We only want to return 255 since this is a bus meta module.
    return 255
}

# Module dependency requirements.
depends() {
    # Add a dbus meta dependency based on the module in use.
    for module in dbus-daemon dbus-broker; do
        if dracut_module_included "$module" ; then
            dbus="$module"
            break
        fi
    done;
}
