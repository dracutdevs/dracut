#!/bin/bash

# called by dracut
check() {
    [[ $mount_needs ]] && return 1

    return 0
}

# called by dracut
depends() {
    echo "systemd"
}

installkernel() {
    return 0
}

# called by dracut
install() {
    inst_multiple -o \
        "$systemdsystemunitdir"/initrd.target \
        "$systemdsystemunitdir"/initrd-fs.target \
        "$systemdsystemunitdir"/initrd-root-device.target \
        "$systemdsystemunitdir"/initrd-root-fs.target \
        "$systemdsystemunitdir"/initrd-usr-fs.target \
        "$systemdsystemunitdir"/initrd-switch-root.target \
        "$systemdsystemunitdir"/initrd-switch-root.service \
        "$systemdsystemunitdir"/initrd-cleanup.service \
        "$systemdsystemunitdir"/initrd-udevadm-cleanup-db.service \
        "$systemdsystemunitdir"/initrd-parse-etc.service

    $SYSTEMCTL -q --root "$initdir" set-default initrd.target
}
