#!/bin/bash

# called by dracut
check() {
    return 255
}

# called by dracut
depends() {
    return "watchdog-modules"
}

# called by dracut
install() {
    # Do not add watchdog hooks if systemd module is included
    # In that case, systemd will manage watchdog kick
    if ! dracut_module_included "systemd"; then
        inst_hook cmdline   00 "$moddir/watchdog.sh"
        inst_hook cmdline   50 "$moddir/watchdog.sh"
        inst_hook pre-trigger 00 "$moddir/watchdog.sh"
        inst_hook initqueue 00 "$moddir/watchdog.sh"
        inst_hook mount     00 "$moddir/watchdog.sh"
        inst_hook mount     50 "$moddir/watchdog.sh"
        inst_hook mount     99 "$moddir/watchdog.sh"
        inst_hook pre-pivot 00 "$moddir/watchdog.sh"
        inst_hook pre-pivot 99 "$moddir/watchdog.sh"
        inst_hook cleanup   00 "$moddir/watchdog.sh"
        inst_hook cleanup   99 "$moddir/watchdog.sh"
    fi

    inst_hook emergency 02 "$moddir/watchdog-stop.sh"
    inst_multiple -o wdctl
}
