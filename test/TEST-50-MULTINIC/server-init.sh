#!/bin/sh
exec </dev/console >/dev/console 2>&1
set -x
export PATH=/sbin:/bin:/usr/sbin:/usr/bin
export TERM=linux
export PS1='nfstest-server:\w\$ '
stty sane
echo "made it to the rootfs!"
echo server > /proc/sys/kernel/hostname
>/dev/watchdog
ip addr add 127.0.0.1/8 dev lo
ip link set lo up
ip addr add 192.168.50.1/24 dev eth0
ip link set eth0 up
>/dev/watchdog
modprobe sunrpc
>/dev/watchdog
mount -t rpc_pipefs sunrpc /var/lib/nfs/rpc_pipefs
>/dev/watchdog
[ -x /sbin/portmap ] && portmap
>/dev/watchdog
[ -x /sbin/rpcbind ] && rpcbind
>/dev/watchdog
modprobe nfsd
>/dev/watchdog
mount -t nfsd nfsd /proc/fs/nfsd
>/dev/watchdog
exportfs -r
>/dev/watchdog
rpc.nfsd
>/dev/watchdog
rpc.mountd
>/dev/watchdog
rpc.idmapd
>/dev/watchdog
exportfs -r
>/dev/watchdog
>/var/lib/dhcpd/dhcpd.leases
>/dev/watchdog
chmod 777 /var/lib/dhcpd/dhcpd.leases
>/dev/watchdog
dhcpd -cf /etc/dhcpd.conf -lf /var/lib/dhcpd/dhcpd.leases
echo -n 'V' > /dev/watchdog
#sh -i
# Wait forever for the VM to die
echo "Serving NFS mounts"
while :; do sleep 30; done
mount -n -o remount,ro /
poweroff -f
