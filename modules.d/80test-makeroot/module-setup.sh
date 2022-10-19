#!/bin/bash

check() {
    # Only include the module if another module requires it
    return 255
}

depends() {
    echo "qemu"
}

install() {
    inst_multiple poweroff cp umount sync dd
    inst_hook initqueue/finished 01 "$moddir/finished-false.sh"
}
