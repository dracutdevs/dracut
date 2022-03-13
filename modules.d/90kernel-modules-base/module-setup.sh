#!/bin/bash

# called by dracut
check() {
    return 0
}

# called by dracut
depends() {
    echo base
    return 0
}

# called by dracut
install() {
    if ! dracut_module_included "systemd"; then
        inst_hook cmdline 01 "$moddir/parse-kernel.sh"
    fi
    inst_simple "$moddir/insmodpost.sh" /sbin/insmodpost.sh
}
