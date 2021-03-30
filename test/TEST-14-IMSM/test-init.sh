#!/bin/sh
. /lib/dracut-lib.sh

export PATH=/sbin:/bin:/usr/sbin:/usr/bin
command -v plymouth > /dev/null 2>&1 && plymouth --quit
exec > /dev/console 2>&1

echo "dracut-root-block-success" | dd oflag=direct,dsync of=/dev/sda
export TERM=linux
export PS1='initramfs-test:\w\$ '
cat /proc/mdstat
[ -f /etc/fstab ] || ln -s /proc/mounts /etc/fstab
stty sane
echo "made it to the rootfs!"
getargbool 0 rd.shell && sh -i
echo "Powering down."
mount -n -o remount,ro /
sync
poweroff -f
