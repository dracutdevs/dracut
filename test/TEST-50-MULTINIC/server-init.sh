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
modprobe sunrpc
mount -t rpc_pipefs sunrpc /var/lib/nfs/rpc_pipefs
[ -x /sbin/portmap ] && portmap
[ -x /sbin/rpcbind ] && rpcbind
modprobe nfsd
mount -t nfsd nfsd /proc/fs/nfsd
exportfs -r
rpc.nfsd
rpc.mountd
rpc.idmapd
exportfs -r
>/var/lib/dhcpd/dhcpd.leases
chmod 777 /var/lib/dhcpd/dhcpd.leases
dhcpd -cf /etc/dhcpd.conf -lf /var/lib/dhcpd/dhcpd.leases
#sh -i
# Wait forever for the VM to die
echo "Serving NFS mounts"
while sleep 30; do echo >/dev/watchdog; done
mount -n -o remount,ro /
poweroff -f
