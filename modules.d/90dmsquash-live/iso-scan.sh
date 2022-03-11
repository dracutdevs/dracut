#!/bin/sh

type getarg > /dev/null 2>&1 || . /lib/dracut-lib.sh

PATH=/usr/sbin:/usr/bin:/sbin:/bin

isofile=$1

[ -z "$isofile" ] && exit 1

copytoram=$2

ismounted "/run/initramfs/isoscan" && exit 0

mkdir -p "/run/initramfs/isoscan"

do_iso_scan() {
    local _name
    local dev
    for dev in /dev/disk/by-uuid/*; do
        _name=$(dev_unit_name "$dev")
        [ -e /tmp/isoscan-"${_name}" ] && continue
        : > /tmp/isoscan-"${_name}"
        mount -t auto -o ro "$dev" "/run/initramfs/isoscan" || continue
        if [ -f "/run/initramfs/isoscan/$isofile" ]; then
            if [ -n "$copytoram" ]; then
                mount -o remount,size=100% /run
                cp "/run/initramfs/isoscan/$isofile" "/run/initramfs/scan.iso"
                losetup -f "/run/initramfs/scan.iso"
                umount "/run/initramfs/isoscan"
                rmdir "/run/initramfs/isoscan"
            else
                losetup -f "/run/initramfs/isoscan/$isofile"
            fi
            ln -s "$dev" /run/initramfs/isoscandev
            rm -f -- "$job"
            exit 0
        else
            umount "/run/initramfs/isoscan"
        fi
    done
}

do_iso_scan

rmdir "/run/initramfs/isoscan"
exit 1
