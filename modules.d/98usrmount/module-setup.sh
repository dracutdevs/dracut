#!/bin/sh

# called by dracut
check() {
    [ -n "$mount_needs" ] && return 1
    return 0
}

# called by dracut
depends() {
    echo 'fs-lib'
}

# called by dracut
install() {
    dracut_module_included "systemd" || inst_hook pre-pivot 50 "$moddir/mount-usr.sh"
    :
}
