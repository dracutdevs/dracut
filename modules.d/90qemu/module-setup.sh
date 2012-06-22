#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    vm=$(systemd-detect-virt --vm &>/dev/null)
    (($? != 0)) && return 255
    [[ $vm = "qemu" ]] && return 0
    [[ $vm = "kvm" ]] && return 0
    return 255
}

installkernel() {
        # qemu specific modules
        hostonly='' instmods virtio_blk virtio virtio_ring virtio_pci ata_piix ata_generic pata_acpi cdrom sr_mod ahci virtio_scsi
}
