#!/bin/sh
umount "$NEWROOT"
lvm lvchange -a n /dev/dracut/root
cryptsetup luksClose /dev/mapper/dracut_crypt_test
poweroff -f