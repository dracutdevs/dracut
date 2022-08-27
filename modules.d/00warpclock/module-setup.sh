#!/bin/bash
# This file is part of dracut.
# SPDX-License-Identifier: GPL-2.0-or-later

# Prerequisite check(s) for module.
check() {

    # hwclock does not exist on S390(x), bail out silently then
    local _arch=${DRACUT_ARCH:-$(uname -m)}
    [ "$_arch" = "s390" -o "$_arch" = "s390x" ] && return 1

    # If the binary(s) requirements are not fulfilled the module can't be installed.
    require_binaries hwclock || return 1

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

    inst_hook pre-trigger 00 "$moddir/warpclock.sh"

    inst_multiple -o \
        /usr/share/zoneinfo/UTC \
        /etc/localtime \
        /etc/adjtime \
        hwclock

}
