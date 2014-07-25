#!/bin/sh
export PATH=/sbin:/bin:/usr/sbin:/usr/bin
exec >/dev/console 2>&1
strstr() { [ "${1##*"$2"*}" != "$1" ]; }
CMDLINE=$(while read line; do echo $line;done < /proc/cmdline)
export TERM=linux
export PS1='initramfs-test:\w\$ '
stty sane
echo "made it to the rootfs! Powering down."
while read dev fs fstype opts rest; do
    [ "$fstype" != "ext3" ] && continue
    echo "iscsi-OK $dev $fstype $opts" > /dev/sda
    break
done < /proc/mounts
#sh -i
if strstr "$CMDLINE" "rd.shell"; then
	strstr "$(setsid --help)" "control" && CTTY="-c"
	setsid $CTTY sh -i
fi
poweroff -f
