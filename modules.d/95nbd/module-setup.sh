#!/bin/sh
# This file is part of dracut.
# SPDX-License-Identifier: GPL-2.0-or-later

# Prerequisite check(s) for module.
check() {
    local _rootdev

    # If an nbd device is not somewhere in the chain of devices root is
    # mounted on, fail the hostonly check.
    [[ $hostonly ]] || [[ $mount_needs ]] && {
        _rootdev=$(find_root_block_device)
        [[ -b /dev/block/$_rootdev ]] || return 1
        check_block_and_slaves block_is_nbd "$_rootdev" || return 255
    }

    # If the binary(s) requirements are not fulfilled
    # return 1 to not include the binary.
    require_binaries nbd-client || return 1

    # Return 255 to only include the module, if another module requires it.
    return 255

}

# Module dependency requirements.
depends() {

    # This module has external dependency on other module(s).
    echo network rootfs-block
    # Return 0 to include the dependent module(s) in the initramfs.
    return 0
}

# Install the required kernel module(s) for the module.
installkernel() {
    instmods nbd
}

# Install the required file(s) for the module.
install() {

    # Install the required binary for module
    inst nbd-client
    # Install the required hook for module
    inst_hook cmdline 90 "$moddir/parse-nbdroot.sh"
    # Install the required script for module
    inst_script "$moddir/nbdroot.sh" "/sbin/nbdroot"

    if dracut_module_included "systemd"; then
        # Install dracuts systemd generator for module
        inst_script "$moddir/nbd-generator.sh" $systemdutildir/system-generators/dracut-nbd-generator
        # Install the type service unit
        $systemdsystemunitdir/nbd@.service

        # Install the hosts local user configurations if enabled.
        if [[ $hostonly ]]; then
            inst_multiple -H -o \
                /etc/nbdtab \
                $systemdsystemconfdir/*.mount \
                $systemdsystemconfdir/nbd@.service \
                $systemdsystemconfdir/nbd@.service.d/*.conf
                ${NULL}
        fi
    fi

    dracut_need_initqueue

}
