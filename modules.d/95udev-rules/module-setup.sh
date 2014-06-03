#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

# called by dracut
install() {
    local _i

    # Fixme: would be nice if we didn't have to guess, which rules to grab....
    # ultimately, /lib/initramfs/rules.d or somesuch which includes links/copies
    # of the rules we want so that we just copy those in would be best
    inst_multiple udevadm cat uname blkid \
        /etc/udev/udev.conf

    [ -d ${initdir}/$systemdutildir ] || mkdir -p ${initdir}/$systemdutildir
    for _i in ${systemdutildir}/systemd-udevd ${udevdir}/udevd /sbin/udevd; do
        [ -x "$_i" ] || continue
        inst "$_i"

        if ! [[ -f  ${initdir}${systemdutildir}/systemd-udevd ]]; then
            ln -fs "$_i" ${initdir}${systemdutildir}/systemd-udevd
        fi
        break
    done
    if ! [[ -e ${initdir}${systemdutildir}/systemd-udevd ]]; then
        derror "Cannot find [systemd-]udevd binary!"
        exit 1
    fi

    inst_rules 50-udev-default.rules 60-persistent-storage.rules \
        61-persistent-storage-edd.rules 80-drivers.rules 95-udev-late.rules \
        60-pcmcia.rules \
        50-udev.rules 95-late.rules \
        50-firmware.rules \
        59-scsi-sg3_utils.rules \
        75-net-description.rules \
        80-net-name-slot.rules 80-net-setup-link.rules \
        "$moddir/59-persistent-storage.rules" \
        "$moddir/61-persistent-storage.rules"

    prepare_udev_rules 59-persistent-storage.rules 61-persistent-storage.rules
    # debian udev rules
    inst_rules 91-permissions.rules
    # eudev rules
    inst_rules 80-drivers-modprobe.rules

    for _i in \
        ${systemdutildir}/network/*.link \
        ${hostonly:+/etc/systemd/network/*.link} \
        ; do
        [[ -e "$_i" ]] && inst "$_i"
    done

    {
        for i in cdrom tape dialout floppy; do
            if ! egrep -q "^$i:" "$initdir/etc/group" 2>/dev/null; then
                if ! egrep "^$i:" /etc/group 2>/dev/null; then
                        case $i in
                            cdrom)   echo "$i:x:11:";;
                            dialout) echo "$i:x:18:";;
                            floppy)  echo "$i:x:19:";;
                            tape)    echo "$i:x:33:";;
                        esac
                fi
            fi
        done
    } >> "$initdir/etc/group"

    inst_multiple -o \
        ${udevdir}/ata_id \
        ${udevdir}/cdrom_id \
        ${udevdir}/create_floppy_devices \
        ${udevdir}/edd_id \
        ${udevdir}/firmware.sh \
        ${udevdir}/firmware \
        ${udevdir}/firmware.agent \
        ${udevdir}/hotplug.functions \
        ${udevdir}/fw_unit_symlinks.sh \
        ${udevdir}/hid2hci \
        ${udevdir}/path_id \
        ${udevdir}/input_id \
        ${udevdir}/scsi_id \
        ${udevdir}/usb_id \
        ${udevdir}/pcmcia-socket-startup \
        ${udevdir}/pcmcia-check-broken-cis

    inst_multiple -o /etc/pcmcia/config.opts

    [ -f /etc/arch-release ] && \
        inst_script "$moddir/load-modules.sh" /lib/udev/load-modules.sh

    inst_libdir_file "libnss_files*"

}

