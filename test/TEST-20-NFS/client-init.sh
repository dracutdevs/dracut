#!/bin/sh
export PATH=/sbin:/bin:/usr/sbin:/usr/bin
exec >/dev/console 2>&1
export TERM=linux
export PS1='initramfs-test:\w\$ '
CMDLINE=$(while read line; do echo $line;done < /proc/cmdline)
strstr() { [ "${1##*"$2"*}" != "$1" ]; }

stty sane
strstr "$CMDLINE" "rd.shell" && sh -i
echo "made it to the rootfs! Powering down."
while read dev fs fstype opts rest; do
    [ "$fstype" != "nfs" -a "$fstype" != "nfs4" ] && continue
    echo "nfs-OK $dev $fstype $opts" > /dev/sda
    break
done < /proc/mounts
#echo 'V' > /dev/watchdog
#sh -i
>/dev/watchdog
poweroff -f
