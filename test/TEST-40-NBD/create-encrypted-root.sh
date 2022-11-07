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

printf test > keyfile
cryptsetup -q luksFormat /dev/disk/by-id/ata-disk_root /keyfile
echo "The passphrase is test"
cryptsetup luksOpen /dev/disk/by-id/ata-disk_root dracut_crypt_test < /keyfile
lvm pvcreate -ff -y /dev/mapper/dracut_crypt_test
lvm vgcreate dracut /dev/mapper/dracut_crypt_test
lvm lvcreate -l 100%FREE -n root dracut
lvm vgchange -ay
udevadm settle
mkfs.ext3 -L dracut -j /dev/dracut/root
mkdir -p /sysroot
mount /dev/dracut/root /sysroot
cp -a -t /sysroot /source/*
umount /sysroot
sleep 1
lvm lvchange -a n /dev/dracut/root
udevadm settle
cryptsetup luksClose /dev/mapper/dracut_crypt_test
udevadm settle
sleep 1
eval "$(udevadm info --query=property --name=/dev/disk/by-id/ata-disk_root | while read -r line || [ -n "$line" ]; do [ "$line" != "${line#*ID_FS_UUID*}" ] && echo "$line"; done)"
{
    echo "dracut-root-block-created"
    echo "ID_FS_UUID=$ID_FS_UUID"
} | dd oflag=direct,dsync of=/dev/disk/by-id/ata-disk_marker
sync
poweroff -f
