#!/bin/sh
. /lib/dracut-lib.sh

export PATH=/sbin:/bin:/usr/sbin:/usr/bin
command -v plymouth > /dev/null 2>&1 && plymouth --quit
exec > /dev/console 2>&1

export TERM=linux
export PS1='initramfs-test:\w\$ '
stty sane
echo "made it to the rootfs! Powering down."
for i in /sys/class/net/*; do
    # booting with network-manager module
    state=/run/NetworkManager/devices/$(cat "$i"/ifindex)
    grep -q connection-uuid= "$state" 2> /dev/null || continue
    i=${i##*/}
    ip link show "$i" | grep -q master && continue
    IFACES="${IFACES}${i} "
done
for i in /run/initramfs/net.*.did-setup; do
    # booting with network-legacy module
    [ -f "$i" ] || continue
    strglobin "$i" ":*:*:*:*:" && continue
    i=${i%.did-setup}
    IFACES="${IFACES}${i##*/net.} "
done
{
    echo "OK"
    echo "$IFACES"
} | dd oflag=direct,dsync of=/dev/disk/by-id/ata-disk_marker

getargbool 0 rd.shell && sh -i

sync
poweroff -f
