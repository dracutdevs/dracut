#!/bin/bash

# called by dracut
installkernel() {
    local _blockfuncs='ahci_platform_get_resources|ata_scsi_ioctl|scsi_add_host|blk_cleanup_queue|register_mtd_blktrans|scsi_esp_register|register_virtio_device|usb_stor_disconnect|mmc_add_host|sdhci_add_host|scsi_add_host_with_dma|blk_mq_alloc_disk|blk_mq_alloc_request|blk_mq_destroy_queue|blk_cleanup_disk'
    local -A _hostonly_drvs

    record_block_dev_drv() {

        for _mod in $(get_dev_module /dev/block/"$1"); do
            _hostonly_drvs["$_mod"]="$_mod"
        done

        for _mod in $(get_blockdev_drv_through_sys "/sys/dev/block/$1"); do
            _hostonly_drvs["$_mod"]="$_mod"
        done

        ((${#_hostonly_drvs[@]} > 0)) && return 0
        return 1
    }

    install_block_modules_strict() {
        hostonly='' instmods "${_hostonly_drvs[@]}"
    }

    install_block_modules() {
        instmods \
            scsi_dh_rdac scsi_dh_emc scsi_dh_alua \
            =drivers/usb/storage \
            =ide nvme vmd \
            virtio_blk virtio_scsi \
            =drivers/ufs

        dracut_instmods -o -s "${_blockfuncs}" "=drivers"
    }

    if [[ -z $drivers ]]; then
        hostonly='' instmods \
            hid_generic unix

        hostonly=$(optional_hostonly) instmods \
            ehci-hcd ehci-pci ehci-platform \
            ohci-hcd ohci-pci \
            uhci-hcd \
            usbhid \
            xhci-hcd xhci-pci xhci-plat-hcd \
            "=drivers/hid" \
            "=drivers/tty/serial" \
            "=drivers/input/serio" \
            "=drivers/input/keyboard" \
            "=drivers/pci/host" \
            "=drivers/pci/controller" \
            "=drivers/pinctrl" \
            "=drivers/usb/typec" \
            "=drivers/watchdog"

        instmods \
            yenta_socket spi_pxa2xx_platform \
            atkbd i8042 firewire-ohci pcmcia hv-vmbus \
            virtio virtio_ring virtio_pci pci_hyperv \
            "=drivers/pcmcia"

        if [[ ${DRACUT_ARCH:-$(uname -m)} == arm* || ${DRACUT_ARCH:-$(uname -m)} == aarch64 || ${DRACUT_ARCH:-$(uname -m)} == riscv* ]]; then
            # arm/aarch64 specific modules
            _blockfuncs+='|dw_mc_probe|dw_mci_pltfm_register|nvme_init_ctrl'
            instmods \
                "=drivers/clk" \
                "=drivers/devfreq" \
                "=drivers/dma" \
                "=drivers/extcon" \
                "=drivers/gpio" \
                "=drivers/hwmon" \
                "=drivers/hwspinlock" \
                "=drivers/interconnect" \
                "=drivers/i2c/busses" \
                "=drivers/mailbox" \
                "=drivers/memory" \
                "=drivers/mfd" \
                "=drivers/mmc/core" \
                "=drivers/mmc/host" \
                "=drivers/nvmem" \
                "=drivers/phy" \
                "=drivers/power" \
                "=drivers/regulator" \
                "=drivers/reset" \
                "=drivers/rpmsg" \
                "=drivers/rtc" \
                "=drivers/soc" \
                "=drivers/spi" \
                "=drivers/usb/chipidea" \
                "=drivers/usb/dwc2" \
                "=drivers/usb/dwc3" \
                "=drivers/usb/host" \
                "=drivers/usb/isp1760" \
                "=drivers/usb/misc" \
                "=drivers/usb/musb" \
                "=drivers/usb/phy" \
                "=drivers/scsi/hisi_sas" \
                "=net/qrtr"
        fi

        awk -F: '/^\// {print $1}' "$srcmods/modules.dep" 2> /dev/null | instmods

        # if not on hostonly mode, or there are hostonly block device
        # install block drivers
        if ! [[ $hostonly ]] \
            || for_each_host_dev_and_slaves_all record_block_dev_drv; then
            hostonly='' instmods sg sr_mod sd_mod scsi_dh ata_piix

            if [[ $hostonly_mode == "strict" ]]; then
                install_block_modules_strict
            else
                install_block_modules
            fi
        fi

        # if not on hostonly mode, install all known filesystems,
        # if the required list is not set via the filesystems variable
        if ! [[ $hostonly ]]; then
            if [[ -z $filesystems ]]; then
                dracut_instmods -o -P ".*/(kernel/fs/nfs|kernel/fs/nfsd|kernel/fs/lockd)/.*" '=fs'
            fi
        elif [[ "${host_fs_types[*]}" ]]; then
            hostonly='' instmods "${host_fs_types[@]}"
        fi

        arch=${DRACUT_ARCH:-$(uname -m)}

        # We don't want to play catch up with hash and encryption algorithms.
        # To be safe, just use the hammer and include all crypto.
        [[ $arch == x86_64 ]] && arch=x86
        [[ $arch == s390x ]] && arch=s390
        [[ $arch == aarch64 ]] && arch=arm64
        hostonly='' instmods "=crypto"
        instmods "=arch/$arch/crypto" "=drivers/crypto"
    fi

    inst_multiple -o "$depmodd/*.conf"
    if [[ $hostonly ]]; then
        inst_multiple -H -o "$depmodconfdir/*.conf"
    fi
    :
}

# called by dracut
install() {
    [[ -d /lib/modprobe.d ]] && inst_multiple -o "/lib/modprobe.d/*.conf"
    [[ -d /usr/lib/modprobe.d ]] && inst_multiple -o "/usr/lib/modprobe.d/*.conf"
    [[ $hostonly ]] && inst_multiple -H -o /etc/modprobe.d/*.conf /etc/modprobe.conf
    if ! dracut_module_included "systemd"; then
        inst_hook cmdline 01 "$moddir/parse-kernel.sh"
    fi
    inst_simple "$moddir/insmodpost.sh" /sbin/insmodpost.sh
    inst_multiple -o sysctl
}
