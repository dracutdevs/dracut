#!/bin/sh
sfdisk /dev/sda <<EOF

;
;
;
EOF
cryptsetup -q luksFormat /dev/sda1 <<EOF
test
EOF
cryptsetup luksOpen /dev/sda1 dracut_crypt_test <<EOF
test
EOF
lvm pvcreate -ff  -y /dev/mapper/dracut_crypt_test
lvm vgcreate dracut /dev/mapper/dracut_crypt_test
lvm lvcreate -l 100%FREE -n root dracut
udevadm settle --timeout=4
[ -b /dev/dracut/root ] || emergency_shell
mke2fs /dev/dracut/root