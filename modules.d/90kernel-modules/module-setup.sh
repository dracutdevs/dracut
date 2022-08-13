#!/bin/bash

# called by dracut
installkernel() {
    local _blockfuncs='ahci_platform_get_resources|ata_scsi_ioctl|scsi_add_host|blk_cleanup_queue|register_mtd_blktrans|scsi_esp_register|register_virtio_device|usb_stor_disconnect|mmc_add_host|sdhci_add_host|scsi_add_host_with_dma|blk_mq_alloc_disk|blk_cleanup_disk'
    local _hostonly_drvs
    _hostonly_drvs=

    record_block_dev_drv() {
        _hostonly_drvs="$_hostonly_drvs $(get_dev_module /dev/block/"$1") $(get_blockdev_drv_through_sys "/sys/dev/block/$1")"
        _hostonly_drvs="${_hostonly_drvs% }"
        _hostonly_drvs="${_hostonly_drvs% }"

        [ -n "$_hostonly_drvs" ]
    }

    install_block_modules_strict() {
        # shellcheck disable=SC2086
        hostonly='' instmods $_hostonly_drvs
    }

    install_block_modules() {
        instmods \
            scsi_dh_rdac scsi_dh_emc scsi_dh_alua \
            =drivers/usb/storage \
            =ide nvme vmd \
            virtio_blk virtio_scsi

        dracut_instmods -o -s "${_blockfuncs}" "=drivers"
    }

    if [ -z "$drivers" ]; then
        hostonly='' instmods \
            hid_generic unix \
            ehci-hcd ehci-pci ehci-platform \
            ohci-hcd ohci-pci \
            uhci-hcd \
            xhci-hcd xhci-pci xhci-plat-hcd

        hostonly=$(optional_hostonly) instmods \
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
            yenta_socket \
            atkbd i8042 usbhid firewire-ohci pcmcia hv-vmbus \
            virtio virtio_ring virtio_pci pci_hyperv \
            "=drivers/pcmcia"

        : "${DRACUT_ARCH:="$(uname -m)"}"
        if [ "${DRACUT_ARCH#arm}" != "$DRACUT_ARCH" ] || [ "${DRACUT_ARCH}" = aarch64 ] || [ "${DRACUT_ARCH#riscv}" != "$DRACUT_ARCH" ]; then
            # arm/aarch64 specific modules
            _blockfuncs="$_blockfuncs|dw_mc_probe|dw_mci_pltfm_register"
            instmods \
                "=drivers/clk" \
                "=drivers/devfreq" \
                "=drivers/dma" \
                "=drivers/extcon" \
                "=drivers/gpio" \
                "=drivers/hwmon" \
                "=drivers/hwspinlock" \
                "=drivers/i2c/busses" \
                "=drivers/mailbox" \
                "=drivers/memory" \
                "=drivers/mfd" \
                "=drivers/mmc/core" \
                "=drivers/mmc/host" \
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
                "=drivers/scsi/hisi_sas"
        fi

        grep ^/ "$srcmods/modules.dep" 2> /dev/null | instmods

        # if not on hostonly mode, or there are hostonly block device
        # install block drivers
        if [ -z "$hostonly" ] \
            || for_each_host_dev_and_slaves_all record_block_dev_drv; then
            hostonly='' instmods sg sr_mod sd_mod scsi_dh ata_piix

            if [ "$hostonly_mode" = "strict" ]; then
                install_block_modules_strict
            else
                install_block_modules
            fi
        fi

        # if not on hostonly mode, install all known filesystems,
        # if the required list is not set via the filesystems variable
        if [ -z "$hostonly" ]; then
            if [ -z "$filesystems" ]; then
                dracut_instmods -o -P ".*/(kernel/fs/nfs|kernel/fs/nfsd|kernel/fs/lockd)/.*" '=fs'
            fi
        elif [ -n "${host_fs_types[*]}" ]; then
            hostonly='' instmods "${host_fs_types[@]}"
        fi

        # We don't want to play catch up with hash and encryption algorithms.
        # To be safe, just use the hammer and include all crypto.
        [ "$DRACUT_ARCH" = x86_64 ] && arch=x86
        [ "$DRACUT_ARCH" = s390x ] && arch=s390
        [ "$DRACUT_ARCH" = aarch64 ] && arch=arm64
        hostonly='' instmods "=crypto"
        instmods "=arch/$arch/crypto" "=drivers/crypto"
    fi

    inst_multiple -o "$depmodd/*.conf"
    if [ -n "$hostonly" ]; then
        inst_multiple -H -o "$depmodconfdir/*.conf"
    fi
    :
}

# called by dracut
install() {
    [ -d /lib/modprobe.d ] && inst_multiple -o "/lib/modprobe.d/*.conf"
    [ -d /usr/lib/modprobe.d ] && inst_multiple -o "/usr/lib/modprobe.d/*.conf"
    [ -n "$hostonly" ] && inst_multiple -H -o /etc/modprobe.d/*.conf /etc/modprobe.conf
    if ! dracut_module_included "systemd"; then
        inst_hook cmdline 01 "$moddir/parse-kernel.sh"
    fi
    inst_simple "$moddir/insmodpost.sh" /sbin/insmodpost.sh
}
