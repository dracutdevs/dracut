#!/bin/sh
for i in /net.*.dhcp; do
    [ "$dev" = "/net.*.dhcp" ] && break
    dev=${i#net.}; dev=${i%.dhcp}
    [ -f "/net.$dev.up" ] && continue
    dhclient -1 -q $dev &
done
wait
    
