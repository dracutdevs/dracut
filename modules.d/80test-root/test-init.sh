#!/bin/sh

export PATH=/usr/sbin:/usr/bin:/sbin:/bin

[ -e /proc/self/mounts ] \
    || (mkdir -p /proc && mount -t proc -o nosuid,noexec,nodev proc /proc)

grep -q '^sysfs /sys sysfs' /proc/self/mounts \
    || (mkdir -p /sys && mount -t sysfs -o nosuid,noexec,nodev sysfs /sys)

grep -q '^devtmpfs /dev devtmpfs' /proc/self/mounts \
    || (mkdir -p /dev && mount -t devtmpfs -o mode=755,noexec,nosuid,strictatime devtmpfs /dev)

grep -q '^tmpfs /run tmpfs' /proc/self/mounts \
    || (mkdir -p /run && mount -t tmpfs -o mode=755,noexec,nosuid,strictatime tmpfs /run)

: > /dev/watchdog

exec > /dev/console 2>&1

. /lib/dracut-lib.sh

command -v plymouth > /dev/null 2>&1 && plymouth --quit

# call the test specific init script if exists
if [ -x /sbin/test-init-run ]; then
    . /sbin/test-init-run
fi

echo "dracut-root-block-success" | dd oflag=direct,dsync of=/dev/disk/by-id/ata-disk_marker status=noxfer

export TERM=linux
export PS1='initramfs-test:\w\$ '
[ -f /etc/mtab ] || ln -sfn /proc/mounts /etc/mtab
[ -f /etc/fstab ] || ln -sfn /proc/mounts /etc/fstab
stty sane
echo "made it to the rootfs!"
if getargbool 0 rd.shell; then
    strstr "$(setsid --help)" "control" && CTTY="-c"
    setsid "$CTTY" sh -i
fi
echo "Powering down."
mount -n -o remount,ro /
sync
poweroff -f
