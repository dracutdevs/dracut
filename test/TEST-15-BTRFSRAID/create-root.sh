#!/bin/sh
# don't let udev and this script step on eachother's toes
for x in 64-lvm.rules 70-mdadm.rules 99-mount-rules; do
    > "/etc/udev/rules.d/$x"
done
udevadm control --reload-rules
# save a partition at the beginning for future flagging purposes
sfdisk -C 524288 -H 2 -S 32 -L /dev/sda <<EOF
,16
,10240
,10240
,10240
EOF
mkfs.btrfs -mraid10 -L root /dev/sda2 /dev/sda3 /dev/sda4
btrfs device scan
set -e
mkdir -p /sysroot 
mount /dev/sda4 /sysroot 
cp -a -t /sysroot /source/* 
umount /sysroot 
echo "dracut-root-block-created" >/dev/sda1
poweroff -f
