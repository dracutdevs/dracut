#!/bin/sh
. /lib/dracut-lib.sh

export PATH=/sbin:/bin:/usr/sbin:/usr/bin
command -v plymouth > /dev/null 2>&1 && plymouth --quit
exec > /dev/console 2>&1

echo "dracut-root-block-success" | dd oflag=direct,dsync of=/dev/sda
export TERM=linux
export PS1='initramfs-test:\w\$ '
[ -f /etc/mtab ] || ln -sfn /proc/mounts /etc/mtab
[ -f /etc/fstab ] || ln -sfn /proc/mounts /etc/fstab
stty sane
echo "made it to the rootfs!"
getargbool 0 rd.shell && sh -i
echo "Powering down."
mount -n -o remount,ro /
#echo " rd.break=shutdown " >> /run/initramfs/etc/cmdline
if [ -d /run/initramfs/etc ]; then
    echo " rd.debug=0 " >> /run/initramfs/etc/cmdline
fi
sync
poweroff -f
