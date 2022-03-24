#!/bin/bash

type source_hook > /dev/null 2>&1 || . /lib/dracut-lib.sh

if [ -e /tmp/cm.done ]; then
    return
fi

while read -r _serv; do
    ifname=$(connmanctl services "$_serv" | grep Interface= | sed 's/^.*Interface=\([^,]*\).*$/\1/')
    source_hook initqueue/online "$ifname"
    /sbin/netroot "$ifname"
done < <(connmanctl services | grep -oE '[^ ]+$')

: > /tmp/cm.done
