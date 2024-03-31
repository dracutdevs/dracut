#!/bin/bash

# called by dracut
check() {
    require_binaries capsh
    return 255
}

# called by dracut
depends() {
    echo base bash
    return 0
}

# called by dracut
install() {
    if ! dracut_module_included "systemd"; then
        inst_hook pre-pivot 00 "$moddir/caps.sh"
        inst "$(find_binary capsh 2> /dev/null)" /usr/sbin/capsh
    else
        dwarning "caps: does not work with systemd in the initramfs"
    fi
}
