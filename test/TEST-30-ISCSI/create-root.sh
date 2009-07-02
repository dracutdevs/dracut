#!/bin/sh
# don't let udev and this script step on eachother's toes
for x in 63-luks.rules 64-lvm.rules 70-mdadm.rules 99-mount-rules; do
    > "/etc/udev/rules.d/$x"
done
udevadm control --reload-rules
mke2fs -F /dev/sda && \
mkdir -p /sysroot && \
mount /dev/sda /sysroot && \
cp -a -t /sysroot /source/* && \
umount /sysroot && \
echo "dracut-root-block-created" >/dev/sdb
poweroff -f

#lvm lvchange -a n /dev/dracut/root && \
#cryptsetup luksClose /dev/mapper/dracut_crypt_test && \
