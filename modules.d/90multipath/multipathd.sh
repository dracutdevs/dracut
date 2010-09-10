#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

if [ -e /etc/multipath.conf -a -e /etc/multipath/wwids ]; then
    modprobe dm-multipath
    multipathd
else
    rm /etc/udev/rules.d/??-multipath.rules 2>/dev/null    
fi

