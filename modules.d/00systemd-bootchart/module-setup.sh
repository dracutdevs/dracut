#!/bin/bash

# called by dracut
check() {
    [[ "$mount_needs" ]] && return 1
    require_binaries $systemdutildir/systemd-bootchart || return 1
    return 255
}

# called by dracut
depends() {
    return 0
}

# called by dracut
install() {
    inst_symlink /init /sbin/init
    inst_multiple $systemdutildir/systemd-bootchart
}
