#!/bin/bash

# called by dracut
installkernel() {
    find_kernel_modules_external () {
        local _OLDIFS
        local external_pattern="^/"

        [[ -f "$srcmods/modules.dep" ]] || return 0

        _OLDIFS=$IFS
        IFS=:
        while read a rest; do
            [[ $a =~ $external_pattern ]] || continue
            printf "%s\n" "$a"
        done < "$srcmods/modules.dep"
        IFS=$_OLDIFS
    }
    local _blockfuncs='ahci_platform_get_resources|ata_scsi_ioctl|scsi_add_host|blk_cleanup_queue|register_mtd_blktrans|scsi_esp_register|register_virtio_device|usb_stor_disconnect|mmc_add_host|sdhci_add_host|scsi_add_host_with_dma'

    if [[ -z $drivers ]]; then
        hostonly='' instmods \
            sr_mod sd_mod scsi_dh ata_piix hid_generic unix \
            ehci-hcd ehci-pci ehci-platform \
            ohci-hcd ohci-pci \
            uhci-hcd \
            xhci-hcd xhci-pci xhci-plat-hcd \
            "=drivers/pinctrl" \
            ${NULL}

        hostonly=$(optional_hostonly) instmods \
            "=drivers/hid" \
            "=drivers/tty/serial" \
            "=drivers/input/serio" \
            "=drivers/input/keyboard" \
            "=drivers/usb/storage" \
            "=drivers/pci/host" \
            ${NULL}

        instmods \
            yenta_socket scsi_dh_rdac scsi_dh_emc scsi_dh_alua \
            atkbd i8042 usbhid firewire-ohci pcmcia hv-vmbus \
            virtio virtio_blk virtio_ring virtio_pci virtio_scsi \
            "=drivers/pcmcia" =ide nvme vmd

        if [[ "$(uname -m)" == arm* || "$(uname -m)" == aarch64 ]]; then
            # arm/aarch64 specific modules
            _blockfuncs+='|dw_mc_probe|dw_mci_pltfm_register'
            instmods \
                "=drivers/clk" \
                "=drivers/dma" \
                "=drivers/extcon" \
                "=drivers/gpio" \
                "=drivers/hwspinlock" \
                "=drivers/i2c/busses" \
                "=drivers/mfd" \
                "=drivers/mmc/core" \
                "=drivers/phy" \
                "=drivers/power" \
                "=drivers/regulator" \
                "=drivers/rpmsg" \
                "=drivers/rtc" \
                "=drivers/soc" \
                "=drivers/usb/chipidea" \
                "=drivers/usb/dwc2" \
                "=drivers/usb/dwc3" \
                "=drivers/usb/host" \
                "=drivers/usb/misc" \
                "=drivers/usb/musb" \
                "=drivers/usb/phy" \
                "=drivers/scsi/hisi_sas" \
                ${NULL}
        fi

        dracut_instmods -o -s "${_blockfuncs}" "=drivers"

        find_kernel_modules_external | instmods

        # if not on hostonly mode, install all known filesystems,
        # if the required list is not set via the filesystems variable
        if ! [[ $hostonly ]]; then
            if [[ -z $filesystems ]]; then
                dracut_instmods -o -P ".*/(kernel/fs/nfs|kernel/fs/nfsd|kernel/fs/lockd)/.*" '=fs'
            fi
        elif [[ "${host_fs_types[*]}" ]]; then
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
