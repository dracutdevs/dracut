#!/bin/sh
# don't let udev and this script step on eachother's toes
for x in 64-lvm.rules 70-mdadm.rules 99-mount-rules; do
    > "/etc/udev/rules.d/$x"
done
rm /etc/lvm/lvm.conf
udevadm control --reload-rules
echo -n test >keyfile
cryptsetup -q luksFormat /dev/sdb /keyfile
echo "The passphrase is test"
cryptsetup luksOpen /dev/sdb dracut_crypt_test </keyfile && \
lvm pvcreate -ff  -y /dev/mapper/dracut_crypt_test && \
lvm vgcreate dracut /dev/mapper/dracut_crypt_test && \
lvm lvcreate -l 100%FREE -n root dracut && \
lvm vgchange -ay && \
mke2fs -j /dev/dracut/root && \
mkdir -p /sysroot && \
mount /dev/dracut/root /sysroot && \
cp -a -t /sysroot /source/* && \
umount /sysroot && \
sleep 1 && \
lvm lvchange -a n /dev/dracut/root && \
sleep 1 && \
cryptsetup luksClose /dev/mapper/dracut_crypt_test && \
sleep 1 && \
echo "dracut-root-block-created" >/dev/sda
poweroff -f
