#!/bin/sh
sfdisk -C 640 -H 2 -S 32 -L /dev/sda <<EOF
,213
,213
,213
;
EOF
mdadm --create /dev/md0 --run --auto=yes --level=5 --raid-devices=3 /dev/sda1 /dev/sda2 /dev/sda3
echo -n test >keyfile
cryptsetup -q luksFormat /dev/md0 /keyfile
echo "The passphrase is test"
cryptsetup luksOpen /dev/md0 dracut_crypt_test </keyfile
lvm pvcreate -ff  -y /dev/mapper/dracut_crypt_test
lvm vgcreate dracut /dev/mapper/dracut_crypt_test
lvm lvcreate -l 100%FREE -n root dracut
udevadm settle --timeout=4
[ -b /dev/dracut/root ] || emergency_shell
mke2fs /dev/dracut/root