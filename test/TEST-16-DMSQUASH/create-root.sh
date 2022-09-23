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

# create a single partition using 50% of the capacity of the image file created by test_setup() in test.sh
sfdisk /dev/disk/by-id/ata-disk_root << EOF
2048,161792
EOF

udevadm settle

mkfs.ext4 -q -L dracut /dev/disk/by-id/ata-disk_root-part1
mkdir -p /root
mount /dev/disk/by-id/ata-disk_root-part1 /root
mkdir -p /root/run /root/testdir
cp -a -t /root /source/*
echo "Creating squashfs"
mksquashfs /source /root/testdir/rootfs.img -quiet
umount /root
echo "dracut-root-block-created" | dd oflag=direct,dsync of=/dev/disk/by-id/ata-disk_marker
poweroff -f
