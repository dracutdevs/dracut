#!/bin/sh
export PATH=/sbin:/bin:/usr/sbin:/usr/bin
strstr() { [ "${1##*"$2"*}" != "$1" ]; }
CMDLINE=$(while read line; do echo $line;done < /proc/cmdline)
command -v plymouth >/dev/null && plymouth --quit
exec >/dev/console 2>&1
echo "dracut-root-block-success" >/dev/sda1
export TERM=linux
export PS1='initramfs-test:\w\$ '
[ -f /etc/mtab ] || ln -sfn /proc/mounts /etc/mtab
[ -f /etc/fstab ] || ln -sfn /proc/mounts /etc/fstab
stty sane
echo "made it to the rootfs!"
strstr "$CMDLINE" "rd.shell" && sh -i
echo "Powering down."
mount -n -o remount,ro /
#echo " rd.break=shutdown " >> /run/initramfs/etc/cmdline
if [ -d /run/initramfs/etc ]; then
    echo " rd.debug=0 " >> /run/initramfs/etc/cmdline
fi
if [ -e /lib/systemd/systemd-shutdown ]; then
    exec /lib/systemd/systemd-shutdown poweroff
fi
poweroff -f
