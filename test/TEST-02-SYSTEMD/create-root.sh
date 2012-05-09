#!/bin/sh
# don't let udev and this script step on eachother's toes
for x in 64-lvm.rules 70-mdadm.rules 99-mount-rules; do
    > "/etc/udev/rules.d/$x"
done
rm /etc/lvm/lvm.conf
udevadm control --reload-rules
set -e
# save a partition at the beginning for future flagging purposes
sfdisk -C 1280 -H 2 -S 32 -L /dev/sda <<EOF
,16
,
EOF

mkfs.ext3 -L dracut /dev/sda2
mkdir -p /root
mount /dev/sda2 /root
cp -a -t /root /source/*
mkdir -p /root/run
umount /root
echo "dracut-root-block-created" >/dev/sda1
poweroff -f

