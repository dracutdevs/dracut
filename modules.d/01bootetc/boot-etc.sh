#!/bin/sh
. /lib/dracut-lib.sh

bootetc=$(getarg bootetc=)
if [ "${bootetc}x" == "x" ]; then
    exit 0
fi

mount_boot bootetc
if [ -d /boot/initrd-etc ] && [ ! -f /run/bootetc.done ]; then
    info "bootetc: Updating initramfs etc from ${bootetc}/initrd-etc"
    copytree /boot/initrd-etc /etc
    touch /run/bootetc.done

    if [ -z "$DRACUT_SYSTEMD" ]; then
        systemctl try-restart dracut-cmdline.service
        systemctl try-restart systemd-udev-trigger.service
    fi
fi

umount /boot >/dev/null 2>&1
