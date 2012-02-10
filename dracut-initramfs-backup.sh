#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

set -e
cd /run/initramfs

if [ "x$1" = "xbackup" ]; then
    compress="gzip"
    command -v pigz > /dev/null 2>&1 && compress="pigz"
    find . |cpio -H newc -o --quiet \
        | pigz > /var/lib/initramfs/_run_initramfs-backup.cpio.gz
    mv -f /var/lib/initramfs/_run_initramfs-backup.cpio.gz \
        /var/lib/initramfs/run_initramfs-backup.cpio.gz
    rm -fr etc bin lib lib64 sbin shutdown tmp usr var
    > .backuped
elif [ "x$1" = "xrestore" ]; then
    [ -f .backuped -a -f /var/lib/initramfs/run_initramfs-backup.cpio.gz ] || exit 1
    zcat /var/lib/initramfs/run_initramfs-backup.cpio.gz  | cpio -id >/dev/null 2>&1
    rm .backuped
    rm -f /var/lib/initramfs/run_initramfs-backup.cpio.gz
fi
