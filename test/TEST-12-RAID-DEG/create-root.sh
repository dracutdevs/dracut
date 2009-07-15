#!/bin/sh
# don't let udev and this script step on eachother's toes
for x in 63-luks.rules 64-lvm.rules 70-mdadm.rules 99-mount-rules; do
    > "/etc/udev/rules.d/$x"
done
udevadm control --reload-rules
# save a partition at the beginning for future flagging purposes
sfdisk -C 640 -H 2 -S 32 -L /dev/sda <<EOF
,1
,213
,213
,213
EOF
mdadm --create /dev/md0 --run --auto=yes --level=5 --raid-devices=3 /dev/sda2 /dev/sda3 /dev/sda4
# wait for the array to finish initailizing, otherwise this sometimes fails
# randomly.
mdadm -W /dev/md0
echo -n test >keyfile
cryptsetup -q luksFormat /dev/md0 /keyfile
echo "The passphrase is test"
cryptsetup luksOpen /dev/md0 dracut_crypt_test </keyfile && \
lvm pvcreate -ff  -y /dev/mapper/dracut_crypt_test && \
lvm vgcreate dracut /dev/mapper/dracut_crypt_test && \
lvm lvcreate -l 100%FREE -n root dracut && \
lvm vgchange -ay && \
mke2fs /dev/dracut/root && \
mkdir -p /sysroot && \
mount /dev/dracut/root /sysroot && \
cp -a -t /sysroot /source/* && \
umount /sysroot && \
lvm lvchange -a n /dev/dracut/root && \
cryptsetup luksClose /dev/mapper/dracut_crypt_test && \
mdadm /dev/md0 --fail /dev/sda2 --remove /dev/sda2 && \
{
/sbin/mdadm --detail --export /dev/md0 > /tmp/mduuid ;
. /tmp/mduuid;
} && \
{
echo "dracut-root-block-created" 
echo MD_UUID=$MD_UUID 
}> /dev/sda1
dd if=/dev/zero of=/dev/sda2
poweroff -f
