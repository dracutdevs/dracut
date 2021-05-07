#!/bin/sh
: > /dev/watchdog
. /lib/dracut-lib.sh

export PATH=/usr/sbin:/usr/bin:/sbin:/bin
command -v plymouth > /dev/null 2>&1 && plymouth --quit
exec > /dev/console 2>&1

while read -r dev fs fstype opts rest || [ -n "$dev" ]; do
    [ "$dev" = "rootfs" ] && continue
    [ "$fs" != "/" ] && continue
    echo "nbd-OK $fstype $opts" | dd oflag=direct,dsync of=/dev/disk/by-id/ata-disk_marker
    echo "nbd-OK $fstype $opts"
    break
done < /proc/mounts
export TERM=linux
export PS1='nbdclient-test:\w\$ '
stty sane
echo "made it to the rootfs! Powering down."

if getargbool 0 rd.shell; then
    strstr "$(setsid --help)" "control" && CTTY="-c"
    setsid $CTTY sh -i
fi

mount -n -o remount,ro /

sync
poweroff -f
