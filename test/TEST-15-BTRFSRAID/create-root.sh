#!/bin/sh

trap 'poweroff -f' EXIT

# don't let udev and this script step on eachother's toes
for x in 64-lvm.rules 70-mdadm.rules 99-mount-rules; do
    : > "/etc/udev/rules.d/$x"
done
modprobe btrfs || :
udevadm control --reload
udevadm settle

set -e

mkfs.btrfs -draid10 -mraid10 -L root /dev/disk/by-id/ata-disk_raid[1234]
udevadm settle

btrfs device scan
udevadm settle

mkdir -p /sysroot
mount -t btrfs /dev/disk/by-id/ata-disk_raid4 /sysroot
cp -a -t /sysroot /source/*
umount /sysroot

echo "dracut-root-block-created" | dd oflag=direct,dsync of=/dev/disk/by-id/ata-disk_marker
sync
poweroff -f
