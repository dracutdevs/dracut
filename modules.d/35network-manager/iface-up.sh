#!/bin/sh

ifname="$1"
action="$2"

[ "$action" != up ] && exit 0

ifindex=$(cat "/sys/class/net/$ifname/ifindex")
[ -z "$ifindex" ] && exit 0

hookdir=/lib/dracut/hooks
state=/run/NetworkManager/devices/$ifindex
sed -n 's/root-path/new_root_path/p;s/next-server/new_next_server/p' < $state > /tmp/dhclient.$ifname.dhcpopts
{
    echo "source_hook initqueue/online $ifname"
    echo "/sbin/netroot $ifname"
} > "$hookdir/initqueue/setup_net_$ifname.sh"
