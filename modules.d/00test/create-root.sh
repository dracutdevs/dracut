#!/bin/sh
sfdisk /dev/sda <<EOF

;
;
;
EOF
echo -n test >keyfile
cryptsetup -q luksFormat /dev/sda1 /keyfile
echo "The passphrase is test"
cryptsetup luksOpen /dev/sda1 dracut_crypt_test </keyfile
lvm pvcreate -ff  -y /dev/mapper/dracut_crypt_test
lvm vgcreate dracut /dev/mapper/dracut_crypt_test
lvm lvcreate -l 100%FREE -n root dracut
udevadm settle --timeout=4
[ -b /dev/dracut/root ] || emergency_shell
mke2fs /dev/dracut/root