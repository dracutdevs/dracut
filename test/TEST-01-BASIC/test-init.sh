#!/bin/sh
: > /dev/watchdog

. /lib/dracut-lib.sh

export PATH=/sbin:/bin:/usr/sbin:/usr/bin
command -v plymouth > /dev/null 2>&1 && plymouth --quit
exec > /dev/console 2>&1

echo "dracut-root-block-success" | dd oflag=direct,dsync of=/dev/sdb
export TERM=linux
export PS1='initramfs-test:\w\$ '
[ -f /etc/mtab ] || ln -sfn /proc/mounts /etc/mtab
[ -f /etc/fstab ] || ln -sfn /proc/mounts /etc/fstab
stty sane
echo "made it to the rootfs!"
if getargbool 0 rd.shell; then
    strstr "$(setsid --help)" "control" && CTTY="-c"
    setsid $CTTY sh -i
fi
echo "Powering down."
mount -n -o remount,ro /
sync
poweroff -f
