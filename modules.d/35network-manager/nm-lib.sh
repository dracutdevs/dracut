#!/bin/bash

type getcmdline >/dev/null 2>&1 || . /lib/dracut-lib.sh

nm_generate_connections()
{
    rm -f /run/NetworkManager/system-connections/*
    /usr/libexec/nm-initrd-generator -- $(getcmdline)

    if getargbool 0 rd.neednet; then
        for i in /usr/lib/NetworkManager/system-connections/* \
                 /run/NetworkManager/system-connections/* \
                 /etc/NetworkManager/system-connections/* \
                 /etc/sysconfig/network-scripts/ifcfg-*; do
            [ -f "$i" ] || continue
            echo '[ -f /tmp/nm.done ]' >$hookdir/initqueue/finished/nm.sh
            break
        done
    fi
}
