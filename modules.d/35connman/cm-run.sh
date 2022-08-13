#!/bin/sh

type source_hook > /dev/null 2>&1 || . /lib/dracut-lib.sh

if [ -e /tmp/cm.done ]; then
    return
fi

connmanctl services | grep -oE '[^ ]+$' | while read -r _serv; do
    ifname=$(connmanctl services "$_serv" | sed -e '/Interface=/s/^.*Interface=\([^,]*\).*$/\1/')
    source_hook initqueue/online "$ifname"
    /sbin/netroot "$ifname"
done

: > /tmp/cm.done
