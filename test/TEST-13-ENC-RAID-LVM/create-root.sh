#!/bin/sh

trap 'poweroff -f' EXIT

# don't let udev and this script step on eachother's toes
set -x
for x in 64-lvm.rules 70-mdadm.rules 99-mount-rules; do
    : > "/etc/udev/rules.d/$x"
done
rm -f -- /etc/lvm/lvm.conf
udevadm control --reload
udevadm settle

set -ex
printf test > keyfile
cryptsetup -q luksFormat /dev/disk/by-id/ata-disk_disk1 /keyfile
cryptsetup -q luksFormat /dev/disk/by-id/ata-disk_disk2 /keyfile
cryptsetup -q luksFormat /dev/disk/by-id/ata-disk_disk3 /keyfile
cryptsetup luksOpen /dev/disk/by-id/ata-disk_disk1 dracut_disk1 < /keyfile
cryptsetup luksOpen /dev/disk/by-id/ata-disk_disk2 dracut_disk2 < /keyfile
cryptsetup luksOpen /dev/disk/by-id/ata-disk_disk3 dracut_disk3 < /keyfile
mdadm --create /dev/md0 --run --auto=yes --level=5 --raid-devices=3 /dev/mapper/dracut_disk1 /dev/mapper/dracut_disk2 /dev/mapper/dracut_disk3
# wait for the array to finish initailizing, otherwise this sometimes fails
# randomly.
mdadm -W /dev/md0
lvm pvcreate -ff -y /dev/md0
lvm vgcreate dracut /dev/md0

lvm lvcreate -l 100%FREE -n root dracut
lvm vgchange -ay
mke2fs /dev/dracut/root
mkdir -p /sysroot
mount /dev/dracut/root /sysroot
cp -a -t /sysroot /source/*
umount /sysroot
lvm lvchange -a n /dev/dracut/root
mdadm -W /dev/md0 || :
mdadm --stop /dev/md0
cryptsetup luksClose /dev/mapper/dracut_disk1
cryptsetup luksClose /dev/mapper/dracut_disk2
cryptsetup luksClose /dev/mapper/dracut_disk3

{
    echo "dracut-root-block-created"
    for i in /dev/disk/by-id/ata-disk_disk[123]; do
        udevadm info --query=env --name="$i" | grep -F 'ID_FS_UUID='
    done
} | dd oflag=direct,dsync of=/dev/disk/by-id/ata-disk_marker
sync
poweroff -f
