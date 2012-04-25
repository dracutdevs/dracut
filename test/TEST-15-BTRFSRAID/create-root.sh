#!/bin/sh
# don't let udev and this script step on eachother's toes
for x in 64-lvm.rules 70-mdadm.rules 99-mount-rules; do
    > "/etc/udev/rules.d/$x"
done
udevadm control --reload-rules
# save a partition at the beginning for future flagging purposes
sfdisk -C 655600 -H 2 -S 32 -L /dev/sda <<EOF
,16
,,E
;
;
,10240
,10240
,10240
,10240
EOF
mkfs.btrfs -draid10 -mraid10 -L root /dev/sda5 /dev/sda6 /dev/sda7 /dev/sda8
udevadm settle
btrfs device scan
udevadm settle
set -e
mkdir -p /sysroot 
mount -t btrfs /dev/sda8 /sysroot 
cp -a -t /sysroot /source/* 
umount /sysroot 
echo "dracut-root-block-created" >/dev/sda1
poweroff -f
