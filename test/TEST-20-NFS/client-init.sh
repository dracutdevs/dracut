#!/bin/sh
export PATH=/sbin:/bin:/usr/sbin:/usr/bin
exec >/dev/console 2>&1
export TERM=linux
export PS1='initramfs-test:\w\$ '
CMDLINE=$(while read line || [ -n "$line" ]; do echo $line;done < /proc/cmdline)
strstr() { [ "${1##*"$2"*}" != "$1" ]; }

stty sane
if strstr "$CMDLINE" "rd.shell"; then
    [ -c /dev/watchdog ] && printf 'V' > /dev/watchdog
	strstr "$(setsid --help)" "control" && CTTY="-c"
	setsid $CTTY sh -i
fi

echo "made it to the rootfs! Powering down."

while read dev fs fstype opts rest || [ -n "$dev" ]; do
    [ "$fstype" != "nfs" -a "$fstype" != "nfs4" ] && continue
    echo "nfs-OK $dev $fstype $opts" > /dev/sda
    break
done < /proc/mounts
>/dev/watchdog
poweroff -f
