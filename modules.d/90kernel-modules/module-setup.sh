#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

installkernel() {
    if [[ -z $drivers ]]; then
        block_module_filter() {
            local _blockfuncs='ahci_init_controller|ata_scsi_ioctl|scsi_add_host|blk_init_queue|register_mtd_blktrans|scsi_esp_register|register_virtio_device|usb_stor_disconnect'
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

        hostonly='' instmods sr_mod sd_mod scsi_dh scsi_dh_rdac scsi_dh_emc ata_piix
        hostonly='' instmods pcmcia firewire-ohci
        hostonly='' instmods usb_storage sdhci sdhci-pci

        # arm specific modules
        hostonly='' instmods sdhci_esdhc_imx mmci sdhci_tegra mvsdio omap omapdrm sdhci_dove ahci_platform pata_imx sata_mv

        # install keyboard support
        hostonly='' instmods atkbd i8042 usbhid hid-apple hid-sunplus hid-cherry hid-logitech hid-logitech-dj hid-microsoft ehci-hcd ohci-hcd uhci-hcd xhci-hcd hid_generic
        # install unix socket support
        hostonly='' instmods unix
        instmods "=drivers/pcmcia" =ide "=drivers/usb/storage"
        find_kernel_modules  |  block_module_filter  |  instmods
        # if not on hostonly mode, install all known filesystems,
        # if the required list is not set via the filesystems variable
        if ! [[ $hostonly ]]; then
            if [[ -z $filesystems ]]; then
                omit_drivers="$omit_drivers|kernel/fs/nfs|kernel/fs/nfsd|kernel/fs/lockd" omit_drivers="${omit_drivers##|}" instmods '=fs'
            fi
        else
            inst_fs() {
                [[ $2 ]] || return 1
                hostonly='' instmods $2
            }
            for_each_host_dev_fs inst_fs
        fi
    else
        hostonly='' instmods $drivers
    fi

    if [[ $add_drivers ]]; then
        hostonly='' instmods -c $add_drivers || return 1
    fi
    if [[ $filesystems ]]; then
        hostonly='' instmods -c $filesystems || return 1
    fi

}

install() {
    local _f i
    [ -f /etc/modprobe.conf ] && dracut_install /etc/modprobe.conf
    set -- /{etc,lib}/modprobe.d/*.conf
    if [[ -f $1 ]]; then
        dracut_install "$@"
    fi
    inst_hook cmdline 01 "$moddir/parse-kernel.sh"
    inst_simple "$moddir/insmodpost.sh" /sbin/insmodpost.sh
}
