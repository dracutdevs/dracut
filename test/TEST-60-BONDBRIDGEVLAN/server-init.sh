#!/bin/sh
exec < /dev/console > /dev/console 2>&1
set -x
export PATH=/usr/sbin:/usr/bin:/sbin:/bin
export TERM=linux
export PS1='nfstest-server:\w\$ '
stty sane
echo "made it to the rootfs!"
echo server > /proc/sys/kernel/hostname

wait_for_if_link() {
    local cnt=0
    local li

    while [ $cnt -lt 600 ]; do
        ip link show

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

udevadm settle

ip link show

wait_for_if_link enx525401123456
wait_for_if_link enx525401123457
wait_for_if_link enx525401123458
wait_for_if_link enx525401123459

ip link set dev enx525401123456 name net1
ip link set dev enx525401123457 name net2
ip link set dev enx525401123458 name net3
ip link set dev enx525401123459 name net4

modprobe -b -q 8021q && modprobe -b -q bonding
: > /dev/watchdog

ip addr add 127.0.0.1/8 dev lo
linkup lo

ip addr add 192.168.50.1/24 dev net1
linkup net1
: > /dev/watchdog

ip link add dev net2.1 link net2 type vlan id 1
ip link add dev net2.2 link net2 type vlan id 2
ip link add dev net2.3 link net2 type vlan id 3
ip link add dev net2.4 link net2 type vlan id 4
ip addr add 192.168.54.1/24 dev net2.1
ip addr add 192.168.55.1/24 dev net2.2
ip addr add 192.168.56.1/24 dev net2.3
ip addr add 192.168.57.1/24 dev net2.4
linkup net2
ip link set dev net2.1 up
ip link set dev net2.2 up
ip link set dev net2.3 up
ip link set dev net2.4 up

ip link add bond0 type bond
ip link set net3 master bond0
ip link set net4 master bond0
ip link set net3 up
ip link set net4 up
ip link set bond0 up
ip addr add 192.168.51.1/24 dev bond0

: > /dev/watchdog
modprobe af_packet
: > /dev/watchdog
modprobe sunrpc
: > /dev/watchdog
mount -t rpc_pipefs sunrpc /var/lib/nfs/rpc_pipefs
: > /dev/watchdog
[ -x /sbin/portmap ] && portmap
: > /dev/watchdog
mkdir -p /run/rpcbind
[ -x /sbin/rpcbind ] && rpcbind
: > /dev/watchdog
modprobe nfsd
: > /dev/watchdog
mount -t nfsd nfsd /proc/fs/nfsd
: > /dev/watchdog
exportfs -r
: > /dev/watchdog
rpc.nfsd
: > /dev/watchdog
rpc.mountd
: > /dev/watchdog
command -v rpc.idmapd > /dev/null && [ -z "$(pidof rpc.idmapd)" ] && rpc.idmapd -S
: > /dev/watchdog
exportfs -r
: > /dev/watchdog
: > /var/lib/dhcpd/dhcpd.leases
: > /dev/watchdog
chmod 777 /var/lib/dhcpd/dhcpd.leases
: > /dev/watchdog
dhcpd -cf /etc/dhcpd.conf -lf /var/lib/dhcpd/dhcpd.leases net1 bond0
#echo -n 'V' : > /dev/watchdog
#sh -i
#tcpdump -i net1
# Wait forever for the VM to die
echo "Serving"
while :; do
    sleep 10
    : > /dev/watchdog
done
mount -n -o remount,ro /
poweroff -f
