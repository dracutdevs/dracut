#!/bin/sh
export PATH=/sbin:/bin:/usr/sbin:/usr/bin
export TERM=linux
export PS1='nbdtest-server:\w\$ '
stty sane
echo "made it to the rootfs!"
echo server > /proc/sys/kernel/hostname
ip addr add 127.0.0.1/8 dev lo
ip link set lo up
ip addr add 192.168.50.1/24 dev eth0
ip link set eth0 up
nbd-server 2000 /dev/sdb -C /dev/null
nbd-server 2001 /dev/sdc -C /dev/null
>/var/lib/dhcpd/dhcpd.leases
chmod 777 /var/lib/dhcpd/dhcpd.leases
dhcpd -cf /etc/dhcpd.conf -lf /var/lib/dhcpd/dhcpd.leases
#sh -i
# Wait forever for the VM to die
while sleep 60; do sleep 60; done
mount -n -o remount,ro /
poweroff -f
