#!/bin/sh

if getargbool 0 rd.debug -d -y rdinitdebug -d -y rdnetdebug; then
    /usr/sbin/NetworkManager --configure-and-quit=initrd --debug --log-level=trace
else
    /usr/sbin/NetworkManager --configure-and-quit=initrd --no-daemon
fi

for _i in /sys/class/net/*/
do
    state=/run/NetworkManager/devices/$(cat $_i/ifindex)
    grep -q connection-uuid= $state 2>/dev/null || continue
    ifname=$(basename $_i)
    sed -n 's/root-path/new_root_path/p' <$state >/tmp/dhclient.$ifname.dhcpopts
    source_hook initqueue/online $ifname
    /sbin/netroot $ifname
done
