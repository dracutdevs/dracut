#!/bin/sh

trap 'poweroff -f' EXIT

# don't let udev and this script step on eachother's toes
for x in 64-lvm.rules 70-mdadm.rules 99-mount-rules; do
    : > "/etc/udev/rules.d/$x"
done
rm -f -- /etc/lvm/lvm.conf
udevadm control --reload
udevadm settle

set -ex

mkfs.ext3 -L '  rdinit=/bin/sh' /dev/disk/by-id/ata-disk_root
mkdir -p /root
mount /dev/disk/by-id/ata-disk_root /root
cp -a -t /root /source/*
mkdir -p /root/run
umount /root
echo "dracut-root-block-created" | dd oflag=direct,dsync of=/dev/disk/by-id/ata-disk_marker
poweroff -f
