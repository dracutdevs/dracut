#!/bin/bash

type getcmdline >/dev/null 2>&1 || . /lib/dracut-lib.sh

nm_generate_connections()
{
    local _found
    
    rm -f /run/NetworkManager/system-connections/*
    /usr/libexec/nm-initrd-generator -- $(getcmdline)

    for i in /usr/lib/NetworkManager/system-connections/* \
                 /run/NetworkManager/system-connections/* \
                 /etc/NetworkManager/system-connections/* \
                 /etc/sysconfig/network-scripts/ifcfg-*; do
        [ -f "$i" ] || continue
        _found=1
        break
    done

    if [ -n "$_found" ]; then
        if getargbool 0 rd.neednet; then
            echo '[ -f /tmp/nm.done ]' >$hookdir/initqueue/finished/nm.sh
        fi
    else
        systemctl disable NetworkManager.service
        systemctl disable dracut-wait-nm.path
        systemctl disable dracut-wait-nm.service
    fi
}
