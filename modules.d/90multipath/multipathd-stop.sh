#!/bin/sh

type pidof > /dev/null 2>&1 || . /lib/dracut-lib.sh

if [ -e /etc/multipath.conf ]; then
    pkill multipathd > /dev/null 2>&1

    if pidof multipathd > /dev/null 2>&1; then
        sleep 0.2
    fi

    if pidof multipathd > /dev/null 2>&1; then
        pkill -9 multipathd > /dev/null 2>&1
    fi
fi
