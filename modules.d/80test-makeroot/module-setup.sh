#!/bin/bash

check() {
    # Only include the module if another module requires it
    return 255
}

depends() {
    echo "dash rootfs-block kernel-modules qemu"
}

installkernel() {
    instmods piix ide-gd_mod ata_piix ext4 sd_mod
}

install() {
    inst_multiple poweroff cp umount sync dd
    inst_hook initqueue/finished 01 "$moddir/finished-false.sh"
}
