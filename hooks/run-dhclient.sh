#!/bin/sh
for i in /net.*.dhcp; do
    dev=${i#net.}; dev=${i%.dhcp}
    dhclient -1 -q $dev &
done
wait
    