#!/bin/bash

type source_hook > /dev/null 2>&1 || . /lib/dracut-lib.sh
type nm_call_hooks > /dev/null 2>&1 || . /lib/nm-lib.sh

if [ -e /tmp/nm.done ]; then
    return
fi

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

if [ -s /run/NetworkManager/initrd/hostname ]; then
    cat /run/NetworkManager/initrd/hostname > /proc/sys/kernel/hostname
fi

for _i in /sys/class/net/*; do
    [ -d "$_i" ] || continue
    state="/run/NetworkManager/devices/$(cat "$_i"/ifindex)"
    grep -q '^connection-uuid=' "$state" 2> /dev/null || continue
    ifname="${_i##*/}"
    nm_call_hooks "$ifname"
done

: > /tmp/nm.done
