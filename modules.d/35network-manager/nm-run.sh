#!/bin/sh

type source_hook > /dev/null 2>&1 || . /lib/dracut-lib.sh

if [ -e /tmp/nm.done ]; then
    return
fi

if [ -z "$DRACUT_SYSTEMD" ]; then
    # Only start NM if networking is needed
    if [ -e /run/NetworkManager/initrd/neednet ]; then
        for i in /usr/lib/NetworkManager/system-connections/* \
            /run/NetworkManager/system-connections/* \
            /etc/NetworkManager/system-connections/* \
            /etc/sysconfig/network-scripts/ifcfg-*; do
            [ -f "$i" ] || continue
            /usr/sbin/NetworkManager --configure-and-quit=initrd --no-daemon
            break
        done
    fi
fi

if [ -s /run/NetworkManager/initrd/hostname ]; then
    cat /run/NetworkManager/initrd/hostname > /proc/sys/kernel/hostname
fi

for _i in /sys/class/net/*; do
    state=/run/NetworkManager/devices/$(cat "$_i"/ifindex)
    grep -q connection-uuid= "$state" 2> /dev/null || continue
    ifname=${_i##*/}
    sed -n 's/root-path/new_root_path/p;s/next-server/new_next_server/p' < "$state" > /tmp/dhclient."$ifname".dhcpopts
    source_hook initqueue/online "$ifname"
    /sbin/netroot "$ifname"
done

: > /tmp/nm.done
