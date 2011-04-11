#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
if [ -z $iscsi_lun ]; then
    iscsi_lun=0
fi
NEWROOT=${NEWROOT:-"/sysroot"}

for disk in /dev/disk/by-path/*-iscsi-*-$iscsi_lun; do
    if mount -t ${fstype:-auto} -o "$rflags" $disk $NEWROOT; then
        if [ ! -d $NEWROOT/proc ]; then
            umount $disk
            continue
        fi
        break
    fi
done
