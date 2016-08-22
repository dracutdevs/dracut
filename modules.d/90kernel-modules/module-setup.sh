#!/bin/bash

# called by dracut
installkernel() {
    local _blockfuncs='ahci_platform_get_resources|ata_scsi_ioctl|scsi_add_host|blk_cleanup_queue|register_mtd_blktrans|scsi_esp_register|register_virtio_device|usb_stor_disconnect|mmc_add_host|sdhci_add_host|scsi_add_host_with_dma'

    if [[ -z $drivers ]]; then
        hostonly='' instmods \
            sr_mod sd_mod scsi_dh ata_piix hid_generic unix \
            ehci-hcd ehci-pci ehci-platform \
            ohci-hcd ohci-pci \
            uhci-hcd \
            xhci-hcd xhci-pci xhci-plat-hcd \
            "=drivers/hid" \
            "=drivers/input/serio" \
            "=drivers/input/keyboard" \
            "=drivers/usb/storage" \
            ${NULL}

        instmods \
            yenta_socket scsi_dh_rdac scsi_dh_emc scsi_dh_alua \
            atkbd i8042 usbhid firewire-ohci pcmcia hv-vmbus \
            virtio virtio_blk virtio_ring virtio_pci virtio_scsi \
            "=drivers/pcmcia" =ide nvme

        if [[ "$(uname -p)" == arm* ]]; then
            # arm specific modules
            instmods \
                "=drivers/clk" \
                "=drivers/i2c/busses" \
                "=drivers/regulator" \
                "=drivers/rtc" \
                "=drivers/usb/host" \
                "=drivers/usb/phy" \
                ${NULL}
        fi

        dracut_instmods -o -s "${_blockfuncs}" "=drivers"

        # if not on hostonly mode, install all known filesystems,
        # if the required list is not set via the filesystems variable
        if ! [[ $hostonly ]]; then
            if [[ -z $filesystems ]]; then
                dracut_instmods -o -P ".*/(kernel/fs/nfs|kernel/fs/nfsd|kernel/fs/lockd)/.*" '=fs'
            fi
        else
            hostonly='' instmods "${host_fs_types[@]}"
        fi
    fi
    :
}

# called by dracut
install() {
    inst_multiple -o /lib/modprobe.d/*.conf
    [[ $hostonly ]] && inst_multiple -H -o /etc/modprobe.d/*.conf /etc/modprobe.conf
    if ! dracut_module_included "systemd"; then
        inst_hook cmdline 01 "$moddir/parse-kernel.sh"
    fi
    inst_simple "$moddir/insmodpost.sh" /sbin/insmodpost.sh
}
