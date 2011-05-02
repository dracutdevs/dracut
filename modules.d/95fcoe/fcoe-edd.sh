#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

dcb=$1

if ! [ -d /sys/firmware/edd ]; then
    modprobe edd
    while ! [ -d /sys/firmware/edd ]; do sleep 0.1; done
fi

for disk in /sys/firmware/edd/int13_*; do
    [ -d $disk ] || continue
    for nic in ${disk}/pci_dev/net/*; do
        [ -d $nic ] || continue
        if [ -e ${nic}/address ]; then
	    fcoe_interface=${nic##*/}
	    if ! [ -e "/tmp/.fcoe-$fcoe_interface" ]; then
		/sbin/fcoe-up $fcoe_interface $dcb
		> "/tmp/.fcoe-$fcoe_interface"
	    fi
        fi
    done
done
modprobe -r edd
