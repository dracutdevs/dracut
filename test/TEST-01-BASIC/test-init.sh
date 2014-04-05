#!/bin/sh
>/dev/watchdog
export PATH=/sbin:/bin:/usr/sbin:/usr/bin
strstr() { [ "${1##*"$2"*}" != "$1" ]; }
CMDLINE=$(while read line; do echo $line;done < /proc/cmdline)
plymouth --quit
exec >/dev/console 2>&1
echo "dracut-root-block-success" >/dev/sdb
export TERM=linux
export PS1='initramfs-test:\w\$ '
[ -f /etc/mtab ] || ln -sfn /proc/mounts /etc/mtab
[ -f /etc/fstab ] || ln -sfn /proc/mounts /etc/fstab
stty sane
echo "made it to the rootfs!"
if strstr "$CMDLINE" "rd.shell"; then
	strstr "$(setsid --help)" "control" && CTTY="-c"
	setsid $CTTY sh -i
fi
echo "Powering down."
mount -n -o remount,ro /
poweroff -f
