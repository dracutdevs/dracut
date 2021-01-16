#!/bin/sh

if [ -e /tmp/nm.done ]; then
    return
fi

for i in /usr/lib/NetworkManager/system-connections/* \
         /run/NetworkManager/system-connections/* \
         /etc/NetworkManager/system-connections/* \
         /etc/sysconfig/network-scripts/ifcfg-*; do
  [ -f "$i" ] || continue
  if getargbool 0 rd.debug -d -y rdinitdebug -d -y rdnetdebug; then
      /usr/sbin/NetworkManager --configure-and-quit=initrd --debug --log-level=trace
  else
      /usr/sbin/NetworkManager --configure-and-quit=initrd --no-daemon
  fi

  if [ -s /run/NetworkManager/initrd/hostname ]; then
      cat /run/NetworkManager/initrd/hostname > /proc/sys/kernel/hostname
  fi
  break
done

for _i in /sys/class/net/*
do
    state=/run/NetworkManager/devices/$(cat $_i/ifindex)
    grep -q connection-uuid= $state 2>/dev/null || continue
    ifname=${_i##*/}
    sed -n 's/root-path/new_root_path/p;s/next-server/new_next_server/p' <$state >/tmp/dhclient.$ifname.dhcpopts
    source_hook initqueue/online $ifname
    /sbin/netroot $ifname
done

> /tmp/nm.done
