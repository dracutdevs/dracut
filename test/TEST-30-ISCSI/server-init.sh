#!/bin/sh
exec </dev/console >/dev/console 2>&1
set -x
export PATH=/sbin:/bin:/usr/sbin:/usr/bin
export TERM=linux
export PS1='nfstest-server:\w\$ '
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
ensure_device eth1 ens4

ip addr add 127.0.0.1/8 dev lo
ip link set lo up
ip addr add 192.168.50.1/24 dev ens3
ip link set ens3 up
ip addr add 192.168.51.1/24 dev ens4
ip link set ens4 up
>/var/lib/dhcpd/dhcpd.leases
chmod 777 /var/lib/dhcpd/dhcpd.leases
dhcpd -d -cf /etc/dhcpd.conf -lf /var/lib/dhcpd/dhcpd.leases &

tgtd
tgtadm --lld iscsi --mode target --op new --tid 1 --targetname iqn.2009-06.dracut:target0
tgtadm --lld iscsi --mode target --op new --tid 2 --targetname iqn.2009-06.dracut:target1
tgtadm --lld iscsi --mode target --op new --tid 3 --targetname iqn.2009-06.dracut:target2
tgtadm --lld iscsi --mode logicalunit --op new --tid 1 --lun 1 -b /dev/sdb
tgtadm --lld iscsi --mode logicalunit --op new --tid 2 --lun 2 -b /dev/sdc
tgtadm --lld iscsi --mode logicalunit --op new --tid 3 --lun 3 -b /dev/sdd
tgtadm --lld iscsi --mode target --op bind --tid 1 -I 192.168.50.101
tgtadm --lld iscsi --mode target --op bind --tid 2 -I 192.168.51.101
tgtadm --lld iscsi --mode target --op bind --tid 3 -I 192.168.50.101


# Wait forever for the VM to die
echo "Serving iSCSI"
while :; do
	[ -n "$(jobs -rp)" ] && echo > /dev/watchdog
	sleep 10
done
mount -n -o remount,ro /
poweroff -f
