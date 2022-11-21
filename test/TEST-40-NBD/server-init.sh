#!/bin/sh
exec < /dev/console > /dev/console 2>&1
set -x
export PATH=/usr/sbin:/usr/bin:/sbin:/bin
export TERM=linux
export PS1='nbdtest-server:\w\$ '
stty sane
echo "made it to the rootfs!"
echo server > /proc/sys/kernel/hostname

wait_for_if_link() {
    local cnt=0
    local li
    while [ $cnt -lt 600 ]; do
        li=$(ip -o link show dev "$1" 2> /dev/null)
        [ -n "$li" ] && return 0
        sleep 0.1
        cnt=$((cnt + 1))
    done
    return 1
}

wait_for_if_up() {
    local cnt=0
    local li
    while [ $cnt -lt 200 ]; do
        li=$(ip -o link show up dev "$1")
        [ -n "$li" ] && return 0
        sleep 0.1
        cnt=$((cnt + 1))
    done
    return 1
}

wait_for_route_ok() {
    local cnt=0
    while [ $cnt -lt 200 ]; do
        li=$(ip route show)
        [ -n "$li" ] && [ -z "${li##*"$1"*}" ] && return 0
        sleep 0.1
        cnt=$((cnt + 1))
    done
    return 1
}

linkup() {
    wait_for_if_link "$1" 2> /dev/null && ip link set "$1" up 2> /dev/null && wait_for_if_up "$1" 2> /dev/null
}

ip addr add 127.0.0.1/8 dev lo
ip link set lo up

wait_for_if_link enx525400123456
ip addr add 192.168.50.1/24 dev enx525400123456
linkup enx525400123456

modprobe af_packet
nbd-server
: > /var/lib/dhcpd/dhcpd.leases
chmod 777 /var/lib/dhcpd/dhcpd.leases
dhcpd -d -cf /etc/dhcpd.conf -lf /var/lib/dhcpd/dhcpd.leases &
echo "Serving NBD disks"
while pidof nbd-server && pidof dhcpd; do
    echo > /dev/watchdog
    sleep 1
done
mount -n -o remount,ro /
poweroff -f
