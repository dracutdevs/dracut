#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh

PATH=/usr/sbin:/usr/bin:/sbin:/bin

isofile=$1

[ -z "$isofile" ] && exit 1

mkdir -p "/run/initramfs/isoscan"
for dev in /dev/disk/by-uuid/*; do
    mount -t auto -o ro "$dev" "/run/initramfs/isoscan" || continue
    if [ -f "/run/initramfs/isoscan/$isofile" ]; then
        losetup -f "/run/initramfs/isoscan/$isofile"
        exit 0
    else
        umount "/run/initramfs/isoscan"
    fi
done

rmdir "/run/initramfs/isoscan"
exit 1
