#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

. /lib/dracut-lib.sh
# run mdadm if udev has settled
info "Assembling MD RAID arrays"
udevadm control --stop-exec-queue
mdadm -As --auto=yes --run 2>&1 | vinfo
mdadm -Is --run 2>&1 | vinfo

# there could still be some leftover devices
# which have had a container added
for md in /dev/md[0-9]* /dev/md/*; do 
    [ -b "$md" ] || continue
    udevinfo="$(udevadm info --query=env --name=$md)"
    strstr "$udevinfo" "MD_UUID=" && continue
    strstr "$udevinfo" "MD_LEVEL=container" && continue
    strstr "$udevinfo" "DEVTYPE=partition" && continue
    mdadm --run "$md" 2>&1 | vinfo
done
unset udevinfo

ln -s /sbin/mdraid-cleanup /pre-pivot/30-mdraid-cleanup.sh 2>/dev/null
ln -s /sbin/mdraid-cleanup /pre-pivot/31-mdraid-cleanup.sh 2>/dev/null
udevadm control --start-exec-queue
