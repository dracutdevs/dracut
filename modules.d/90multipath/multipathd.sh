#!/bin/sh

if [ -e /etc/multipath.conf ]; then
        modprobe dm-multipath
	multipathd
fi

