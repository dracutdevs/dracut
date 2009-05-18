#!/bin/sh
for i in /net.*.dhcp; do
    [ "$dev" = '/net.*.dhcp' ] && break
    dev=${i#/net.}; dev=${dev%.dhcp}
    [ -f "/net.$dev.up" ] && continue
    dhclient  -R 'subnet-mask,broadcast-address,time-offset,routers,domain-name,domain-name-servers,host-name,nis-domain,nis-servers,ntp-servers,root-path' -1 -q $dev &
done
wait
    
