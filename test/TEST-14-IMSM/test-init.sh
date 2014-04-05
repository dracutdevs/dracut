#!/bin/sh
export PATH=/sbin:/bin:/usr/sbin:/usr/bin
strstr() { [ "${1##*"$2"*}" != "$1" ]; }
CMDLINE=$(while read line; do echo $line;done < /proc/cmdline)
plymouth --quit
exec >/dev/console 2>&1
echo "dracut-root-block-success" >/dev/sda
export TERM=linux
export PS1='initramfs-test:\w\$ '
cat /proc/mdstat
[ -f /etc/fstab ] || ln -s /proc/mounts /etc/fstab
stty sane
echo "made it to the rootfs!"
strstr "$CMDLINE" "rd.shell" && sh -i
echo "Powering down."
mount -n -o remount,ro /
poweroff -f
