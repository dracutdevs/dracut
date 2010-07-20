#!/bin/sh

if [ -e /etc/multipath.conf -a -e /etc/multipath/wwids ]; then
    modprobe dm-multipath
    multipathd
else
    rm /etc/udev/rules.d/??-multipath.rules 2>/dev/null    
fi

