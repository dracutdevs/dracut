#!/bin/sh

trap 'poweroff -f' EXIT

# don't let udev and this script step on eachother's toes
for x in 64-lvm.rules 70-mdadm.rules 99-mount-rules; do
    : > "/etc/udev/rules.d/$x"
done
rm -f -- /etc/lvm/lvm.conf
udevadm control --reload
set -e

udevadm settle
modprobe btrfs || :
mkfs.btrfs -L dracut /dev/disk/by-id/ata-disk_root
mkfs.btrfs -L dracutusr /dev/disk/by-id/ata-disk_usr
btrfs device scan /dev/disk/by-id/ata-disk_root
btrfs device scan /dev/disk/by-id/ata-disk_usr
mkdir -p /root
mount -t btrfs /dev/disk/by-id/ata-disk_root /root
[ -d /root/usr ] || mkdir -p /root/usr
mount -t btrfs /dev/disk/by-id/ata-disk_usr /root/usr
btrfs subvolume create /root/usr/usr
umount /root/usr
mount -t btrfs -o subvol=usr /dev/disk/by-id/ata-disk_usr /root/usr
cp -a -t /root /source/*
mkdir -p /root/run
btrfs filesystem sync /root/usr
btrfs filesystem sync /root
umount /root/usr
umount /root
echo "dracut-root-block-created" | dd oflag=direct,dsync of=/dev/disk/by-id/ata-disk_marker
poweroff -f
