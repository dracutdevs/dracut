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
    local _d
    local _systemctl
    inst_multiple umount losetup stat sleep timeout
    _systemctl=$(find_binary systemctl 2> /dev/null)
    if dracut_module_included "systemd" && [ -n "$_systemctl" ]; then
        ln_r "$_systemctl" "/sbin/reboot"
        ln_r "$_systemctl" "/sbin/halt"
        ln_r "$_systemctl" "/sbin/poweroff"
    else
        inst_multiple reboot halt poweroff
    fi
    inst_multiple -o kexec
    inst "$moddir/shutdown.sh" "$prefix/shutdown"
    [ -e "${initdir}/lib" ] || mkdir -m 0755 -p "${initdir}"/lib
    mkdir -m 0755 -p "${initdir}"/lib/dracut
    mkdir -m 0755 -p "${initdir}"/lib/dracut/hooks
    for _d in $hookdirs shutdown shutdown-emergency; do
        mkdir -m 0755 -p "${initdir}"/lib/dracut/hooks/"$_d"
    done
}
