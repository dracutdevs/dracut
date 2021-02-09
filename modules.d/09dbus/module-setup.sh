#!/bin/sh
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
    # Add a dbus meta dependency based on the module in use.
    for _module in dbus-daemon dbus-broker; do
        if dracut_module_included "$_module" ; then
            echo "$_module"
            return 0
        fi
    done;

    if find_binary dbus-broker &> /dev/null ; then
        echo "dbus-broker"
        return 0
    else
        echo "dbus-daemon"
        return 0
    fi

    return 1
}
