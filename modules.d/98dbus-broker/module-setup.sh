#!/bin/bash

# called by dracut
check() {
    require_binaries dbus-broker-launch || return 0
    require_binaries dbus-broker || return 0
    require_binaries busctl || return 0
    return 255
}

# called by dracut
depends() {
    echo systemd
    return 0
}

# called by dracut
install() {
    inst_multiple \
        dbus-broker-launch \
        dbus-broker \
        busctl
    
    inst_simple "${systemdsystemunitdir}/dbus.socket"
    inst_simple "${systemdsystemunitdir}/dbus-broker.service"
    inst_simple "/usr/share/dbus-1/system.conf"
   
    grep '^dbus:' $dracutsysrootdir/etc/passwd 2>/dev/null >> "$initdir/etc/passwd"
    grep '^dbus:' $dracutsysrootdir/etc/group >> "$initdir/etc/group"

    systemctl -q --root "$initdir" enable dbus.socket    
    systemctl -q --root "$initdir" enable dbus-broker.service    
}
