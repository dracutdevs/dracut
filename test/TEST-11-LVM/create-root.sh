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
for dev in /dev/disk/by-id/ata-disk_disk[123]; do
    lvm pvcreate -ff -y "$dev"
done

lvm vgcreate dracut /dev/disk/by-id/ata-disk_disk[123]
lvm lvcreate -l 100%FREE -n root dracut
lvm vgchange -ay
mke2fs /dev/dracut/root
mkdir -p /sysroot
mount /dev/dracut/root /sysroot
cp -a -t /sysroot /source/*
umount /sysroot
lvm lvchange -a n /dev/dracut/root
echo "dracut-root-block-created" | dd oflag=direct,dsync of=/dev/disk/by-id/ata-disk_marker
poweroff -f
