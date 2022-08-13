#!/bin/sh

# called by dracut
check() {
    [ -n "$hostonly" ] && return 255

    if [ -n "$mount_needs" ]; then
        is_qemu_virtualized && return 0
        return 255
    fi

    return 0
}

# called by dracut
installkernel() {
    # qemu specific modules
    hostonly=$(optional_hostonly) instmods virtio_net e1000 8139cp pcnet32 e100 ne2k_pci
}
