#!/bin/sh
# don't let udev and this script step on eachother's toes
for x in 63-luks.rules 64-lvm.rules 70-mdadm.rules 99-mount-rules; do
    > "/etc/udev/rules.d/$x"
done
udevadm control --reload-rules
# save a partition at the beginning for future flagging purposes
sfdisk -C 640 -H 2 -S 32 -L /dev/sda <<EOF
,,
EOF
#mdadm --create /dev/md0 --run --auto=yes --level=5 --raid-devices=3 /dev/sda2 /dev/sda3 /dev/sda4
# wait for the array to finish initailizing, otherwise this sometimes fails
# randomly.
#mdadm -W /dev/md0
#echo -n test >keyfile
#cryptsetup -q luksFormat /dev/sda1 /keyfile
#echo "The passphrase is test"
#cryptsetup luksOpen /dev/sda1 dracut_crypt_test </keyfile && \
#lvm pvcreate -ff  -y /dev/mapper/dracut_crypt_test && \
#lvm vgcreate dracut /dev/mapper/dracut_crypt_test && \
#lvm pvcreate -ff  -y /dev/sda1 && \
#lvm vgcreate dracut /dev/sda1 && \
#lvm lvcreate -l 100%FREE -n root dracut && \
#lvm vgchange -ay && \
mke2fs -L ROOT /dev/sda1 && \
mkdir -p /sysroot && \
mount /dev/sda1 /sysroot && \
cp -a -t /sysroot /source/* && \
umount /sysroot && \
echo "dracut-root-block-created" >/dev/sdb
poweroff -f

#lvm lvchange -a n /dev/dracut/root && \
#cryptsetup luksClose /dev/mapper/dracut_crypt_test && \
