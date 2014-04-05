#!/bin/sh
exec >/dev/console 2>&1
set -x
export PATH=/sbin:/bin:/usr/sbin:/usr/bin
strstr() { [ "${1##*"$2"*}" != "$1" ]; }
strglobin() { [ -n "$1" -a -z "${1##*$2*}" ]; }
CMDLINE=$(while read line; do echo $line;done < /proc/cmdline)
export TERM=linux
export PS1='initramfs-test:\w\$ '
stty sane
echo "made it to the rootfs! Powering down."
for i in /run/initramfs/net.*.did-setup; do
	strglobin "$i" ":*:*:*:*:" && continue
	i=${i%.did-setup}
	IFACES+="${i##*/net.} "
done
{
    echo "OK"
    echo "$IFACES"
} > /dev/sda

strstr "$CMDLINE" "rd.shell" && sh -i
poweroff -f
