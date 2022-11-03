#!/bin/sh

type getarg > /dev/null 2>&1 || . /lib/dracut-lib.sh

if [ "$(getarg rd.multipath)" = "default" ] && [ ! -e /etc/multipath.conf ]; then
    # mpathconf requires /etc/multipath to already exist
    mkdir -p /etc/multipath
    mpathconf --enable
fi

if getargbool 1 rd.multipath -d -n rd_NO_MULTIPATH && [ -e /etc/multipath.conf ]; then
    modprobe dm-multipath
    multipathd -B || multipathd
    need_shutdown
else
    rm -- /etc/udev/rules.d/??-multipath.rules 2> /dev/null
fi
