#!/bin/bash

# called by dracut
check() {
    require_binaries sed grep connmand connmanctl connmand-wait-online || return 1

    # do not add this module by default
    return 255
}

# called by dracut
depends() {
    echo dbus systemd bash net-lib
    return 0
}

# called by dracut
installkernel() {
    return 0
}

# called by dracut
install() {
    # We don't need `ip` but having it is *really* useful for people debugging
    # in an emergency shell.
    inst_multiple ip sed grep

    inst connmand
    inst connmanctl
    inst connmand-wait-online
    inst "$dbussystem"/connman.conf
    [[ $hostonly ]] && [[ -f $dracutsysrootdir/etc/connman/main.conf ]] && inst /etc/connman/main.conf
    inst_dir /usr/lib/connman/plugins
    inst_dir /var/lib/connman

    inst_hook cmdline 99 "$moddir/cm-config.sh"

    inst_simple "$moddir"/cm-initrd.service "$systemdsystemunitdir"/cm-initrd.service
    inst_simple "$moddir"/cm-wait-online-initrd.service "$systemdsystemunitdir"/cm-wait-online-initrd.service

    $SYSTEMCTL -q --root "$initdir" enable cm-initrd.service

    inst_hook initqueue/settled 99 "$moddir/cm-run.sh"

    inst_simple "$moddir/cm-lib.sh" "/lib/cm-lib.sh"
}
