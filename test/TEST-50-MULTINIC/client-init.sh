#!/bin/sh
exec >/dev/console 2>&1
set -x
export PATH=/sbin:/bin:/usr/sbin:/usr/bin
strstr() { [ "${1#*$2*}" != "$1" ]; }
CMDLINE=$(while read line; do echo $line;done < /proc/cmdline)
export TERM=linux
export PS1='initramfs-test:\w\$ '
stty sane
echo "made it to the rootfs! Powering down."
[ -e /dev/.initramfs/net.ifaces ] && echo OK $(cat /dev/.initramfs/net.ifaces) > /dev/sda
[ -e /run/initramfs/net.ifaces ] && echo OK $(cat /run/initramfs/net.ifaces) > /dev/sda
strstr "$CMDLINE" "rd.shell" && sh -i
poweroff -f
