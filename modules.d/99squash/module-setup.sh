#!/bin/bash

check() {
    if ! dracut_module_included "systemd-initrd"; then
        derror "dracut-squash only supports systemd bases initramfs"
        return 1
    fi

    if ! type -P mksquashfs >/dev/null || ! type -P unsquashfs >/dev/null ; then
        derror "dracut-squash module requires squashfs-tools"
        return 1
    fi

    for i in squashfs loop overlay; do
        if ! check_kernel_module $i; then
            derror "dracut-squash module requires kernel module $i"
            return 1
        fi
    done

    return 255
}

depends() {
    echo "bash systemd-initrd"
    return 0
}

installkernel() {
    hostonly="" instmods squashfs loop overlay
}

install() {
    inst_multiple kmod modprobe mount mkdir ln echo
    inst $moddir/setup-squash.sh /squash/setup-squash.sh
    inst $moddir/clear-squash.sh /squash/clear-squash.sh
    inst $moddir/init.sh /squash/init.sh

    inst "$moddir/squash-mnt-clear.service" "$systemdsystemunitdir/squash-mnt-clear.service"
    systemctl -q --root "$initdir" add-wants initrd-switch-root.target squash-mnt-clear.service
}
