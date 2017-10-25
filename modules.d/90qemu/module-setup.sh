#!/bin/bash

# called by dracut
check() {
    if [[ $hostonly ]] || [[ $mount_needs ]]; then
        if type -P systemd-detect-virt >/dev/null 2>&1; then
            vm=$(systemd-detect-virt --vm 2>/dev/null)
            (($? != 0)) && return 255
            [[ $vm = "qemu" ]] && return 0
            [[ $vm = "kvm" ]] && return 0
            [[ $vm = "bochs" ]] && return 0
        fi

        for i in /sys/class/dmi/id/*_vendor; do
            [[ -f $i ]] || continue
            read vendor < $i
            [[ "$vendor" == "QEMU" ]] && return 0
            [[ "$vendor" == "Red Hat" ]] && return 0
            [[ "$vendor" == "Bochs" ]] && return 0
        done

        return 255
    fi

    return 0
}

# called by dracut
installkernel() {
    # qemu specific modules
    hostonly='' instmods \
            ata_piix ata_generic pata_acpi cdrom sr_mod ahci \
            virtio_blk virtio virtio_ring virtio_pci \
            virtio_scsi virtio_console virtio_rng \
            spapr-vscsi \
            qemu_fw_cfg
}
