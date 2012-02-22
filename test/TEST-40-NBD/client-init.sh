#!/bin/sh
export PATH=/sbin:/bin:/usr/sbin:/usr/bin
exec >/dev/console 2>&1
while read dev fs fstype opts rest; do
    [ "$dev" = "rootfs" ] && continue
    [ "$fs" != "/" ] && continue
    echo "nbd-OK $fstype $opts" >/dev/sda
    echo "nbd-OK $fstype $opts" 
    break
done < /proc/mounts
export TERM=linux
export PS1='nbdclient-test:\w\$ '
stty sane
echo "made it to the rootfs! Powering down."
#sh -i
mount -n -o remount,ro / &> /dev/null
poweroff -f
