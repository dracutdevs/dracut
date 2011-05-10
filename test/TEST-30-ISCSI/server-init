#!/bin/sh
export PATH=/sbin:/bin:/usr/sbin:/usr/bin
export TERM=linux
export PS1='nfstest-server:\w\$ '
stty sane
echo "made it to the rootfs!"
echo server > /proc/sys/kernel/hostname
ip addr add 127.0.0.1/8 dev lo
ip link set lo up
ip addr add 192.168.50.1/24 dev eth0
ip link set eth0 up
>/var/lib/dhcpd/dhcpd.leases
chmod 777 /var/lib/dhcpd/dhcpd.leases
dhcpd -cf /etc/dhcpd.conf -lf /var/lib/dhcpd/dhcpd.leases
# Wait forever for the VM to die
/usr/sbin/iscsi-target -D -t iqn.2009-06.dracut
mount -n -o remount,ro /
poweroff -f
