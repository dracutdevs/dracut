#!/bin/sh

type nm_generate_connections >/dev/null 2>&1 || . /lib/nm-lib.sh

if [ -n "$netroot" ] || [ -e /tmp/net.ifaces ]; then
    echo rd.neednet >> /etc/cmdline.d/35-neednet.conf
fi

nm_generate_connections

if [ -s /run/NetworkManager/initrd/hostname ]; then
    cat /run/NetworkManager/initrd/hostname > /proc/sys/kernel/hostname || :
fi

if [ "$RD_DEBUG" = yes ]; then
    sed -i "s/^level=.*/level=debug/" /etc/NetworkManager/NetworkManager.conf
fi
