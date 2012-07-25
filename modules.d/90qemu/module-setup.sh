#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    if type -P systemd-detect-virt &>/dev/null; then
        vm=$(systemd-detect-virt --vm &>/dev/null)
        (($? != 0)) && return 255
        [[ $vm = "qemu" ]] && return 0
        [[ $vm = "kvm" ]] && return 0
        [[ $vm = "bochs" ]] && return 0
    fi

    for i in /sys/class/dmi/id/*_vendor; do
        [[ -f $i ]] || continue
        read vendor < $i
        [[  "$vendor" == "QEMU" ]] && return 0
        [[  "$vendor" == "Bochs" ]] && return 0
    done
    return 255
}

installkernel() {
        # qemu specific modules
        hostonly='' instmods virtio_blk virtio virtio_ring virtio_pci ata_piix ata_generic pata_acpi cdrom sr_mod ahci virtio_scsi
}
