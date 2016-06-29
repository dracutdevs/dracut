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

(
    echo OK
    cd /sys/class/net
    for i in ens*; do
	echo "$i" "$(cat $i/mtu)" "$(cat $i/address)"
    done
    echo END
) > /dev/sda

strstr "$CMDLINE" "rd.shell" && sh -i
poweroff -f
