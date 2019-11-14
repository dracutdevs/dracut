#!/bin/sh
exec </dev/console >/dev/console 2>&1
set -x
export PATH=/sbin:/bin:/usr/sbin:/usr/bin
export TERM=linux
export PS1='nbdtest-server:\w\$ '
stty sane
echo "made it to the rootfs!"
echo server > /proc/sys/kernel/hostname

# params: ensure_device <old> <new>
# waits for device and renames it to <new> if needed
ensure_device() {
    local cnt=0
    local li
    while [ $cnt -lt 600 ]; do
        local _if
        for _if in $*; do
           li=$(ip -o link show dev $_if 2>/dev/null)
           [ -n "$li" ] && {
                [[ $_if == $1 ]] && ip link set dev $1 name $2
	            return 0
           }
        sleep 0.1
        cnt=$(($cnt+1))
        done
    done
    return 1
}

ensure_device eth0 ens3

ip addr add 127.0.0.1/8 dev lo
ip link set lo up
ip addr add 192.168.50.1/24 dev ens3
ip link set ens3 up
modprobe af_packet
nbd-server
>/var/lib/dhcpd/dhcpd.leases
chmod 777 /var/lib/dhcpd/dhcpd.leases
dhcpd -d -cf /etc/dhcpd.conf -lf /var/lib/dhcpd/dhcpd.leases &
echo "Serving NBD disks"
while :; do
	[ -n "$(jobs -rp)" ] && echo > /dev/watchdog
	sleep 10
done
mount -n -o remount,ro /
poweroff -f
