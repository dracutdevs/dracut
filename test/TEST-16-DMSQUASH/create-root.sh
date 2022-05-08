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
mkfs.ext4 -q -L dracut /dev/disk/by-id/ata-disk_root
mkdir -p /root
mount /dev/disk/by-id/ata-disk_root /root
mkdir -p /root/run /root/testdir
echo "Creating squashfs"
mksquashfs /source /root/testdir/rootfs.img -quiet
umount /root
echo "dracut-root-block-created" | dd oflag=direct,dsync of=/dev/disk/by-id/ata-disk_marker
poweroff -f
