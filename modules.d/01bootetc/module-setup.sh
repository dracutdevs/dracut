#!/bin/bash

# called by dracut
check() {
    return 0
}

# called by dracut
depends() {
    return 0
}

# called by dracut
install() {
    inst_simple "$moddir/boot-etc.sh" "/sbin/boot-etc"

    if dracut_module_included "systemd"; then
        inst_simple "${moddir}/boot-etc.service" "${systemdsystemunitdir}/boot-etc.service"
        systemctl -q --root "$initdir" enable boot-etc.service
    else
        inst_hook pre-trigger 01 "$moddir/boot-etc.sh"
    fi

}
