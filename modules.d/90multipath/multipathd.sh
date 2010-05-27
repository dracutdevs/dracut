#!/bin/sh

if [ -e /etc/multipath.conf ]; then
    modprobe dm-multipath
    multipathd
else
    rm /etc/udev/rules.d/??-multipath.rules 2>/dev/null    
fi

