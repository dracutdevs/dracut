#!/bin/sh

if [ "$(getarg rd.multipath)" = "default" ] && [ ! -e /etc/multipath.conf ]; then
    mkdir -p /etc/multipath/multipath.conf.d
    mpathconf --enable
fi

if getargbool 1 rd.multipath -d -n rd_NO_MULTIPATH && [ -e /etc/multipath.conf ]; then
    modprobe dm-multipath
    multipathd -B || multipathd
    need_shutdown
else
    rm -- /etc/udev/rules.d/??-multipath.rules 2>/dev/null
fi

