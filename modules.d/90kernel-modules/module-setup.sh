#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

installkernel() {
    if [[ -z $drivers ]]; then
        block_module_filter() {
            local _blockfuncs='ahci_platform_get_resources|ata_scsi_ioctl|scsi_add_host|blk_cleanup_queue|register_mtd_blktrans|scsi_esp_register|register_virtio_device|usb_stor_disconnect|mmc_add_host|sdhci_add_host'
            # subfunctions inherit following FDs
            local _merge=8 _side2=9
            function bmf1() {
                local _f
                while read _f; do case "$_f" in
                    *.ko)    [[ $(<         $_f) =~ $_blockfuncs ]] && echo "$_f" ;;
                    *.ko.gz) [[ $(gzip -dc <$_f) =~ $_blockfuncs ]] && echo "$_f" ;;
                    *.ko.xz) [[ $(xz -dc   <$_f) =~ $_blockfuncs ]] && echo "$_f" ;;
                    esac
                done
                return 0
            }
            function rotor() {
                local _f1 _f2
                while read _f1; do
                    echo "$_f1"
                    if read _f2; then
                        echo "$_f2" 1>&${_side2}
                    fi
                done | bmf1 1>&${_merge}
                return 0
            }
            # Use two parallel streams to filter alternating modules.
            set +x
            eval "( ( rotor ) ${_side2}>&1 | bmf1 ) ${_merge}>&1"
            [[ $debug ]] && set -x
            return 0
        }

        hostonly='' instmods \
            sr_mod sd_mod scsi_dh ata_piix hid_generic unix \
            ehci-hcd ehci-pci ehci-platform \
            ohci-hcd ohci-pci \
            uhci-hcd \
            xhci-hcd xhci-pci xhci-plat-hcd

        instmods yenta_socket scsi_dh_rdac scsi_dh_emc scsi_dh_alua \
                 atkbd i8042 usbhid firewire-ohci pcmcia hv-vmbus \
                 atkbd i8042 usbhid firewire-ohci pcmcia usb_storage \
                 nvme hv-vmbus sdhci_acpi nfit

        instmods \
            "=drivers/hid" \
            "=drivers/input/serio" \
            "=drivers/input/keyboard"

	if [[ "$(uname -m)" == arm* || "$(uname -m)" == aarch64 ]]; then
            # arm/aarch64 specific modules
            hostonly='' instmods \
	        connector-hdmi connector-dvi encoder-tfp410 \
	        encoder-tpd12s015 i2c-tegra gpio-regulator \
		as3722-regulator orion-ehci ehci-tegra
            instmods \
                "=drivers/dma" \
                "=drivers/i2c/busses" \
                "=drivers/regulator" \
                "=drivers/rtc" \
                "=drivers/usb/host" \
                "=drivers/usb/phy" \
		"=drivers/scsi/hisi_sas" \
                ${NULL}
        fi

        # install virtual machine support
        instmods virtio virtio_blk virtio_ring virtio_pci virtio_scsi \
            "=drivers/pcmcia" =ide "=drivers/usb/storage"

        find_kernel_modules  |  block_module_filter  |  instmods

        # if not on hostonly mode, install all known filesystems,
        # if the required list is not set via the filesystems variable
        if ! [[ $hostonly ]]; then
            if [[ -z $filesystems ]]; then
                silent_omit_drivers="kernel/fs/nfs|kernel/fs/nfsd|kernel/fs/lockd" \
                    instmods '=fs'
            fi
        else
            for i in "${host_fs_types[@]}"; do
                hostonly='' instmods $i
            done
        fi
    fi
    :
}

install() {
    inst_multiple -o /lib/modprobe.d/*.conf
    [[ $hostonly ]] && inst_multiple -o /etc/modprobe.d/*.conf /etc/modprobe.conf
    if ! dracut_module_included "systemd"; then
        inst_hook cmdline 01 "$moddir/parse-kernel.sh"
    fi
    inst_simple "$moddir/insmodpost.sh" /sbin/insmodpost.sh
}
