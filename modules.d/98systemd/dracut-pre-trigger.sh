#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

if [ -f /dracut-state.sh ]; then
    . /dracut-state.sh 2>/dev/null
fi
type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh

source_conf /etc/conf.d

getargbool 0 rd.udev.info -y rdudevinfo && udevadm control --log-priority=info
getargbool 0 rd.udev.debug -y rdudevdebug && udevadm control --log-priority=debug
udevproperty "hookdir=$hookdir"

source_hook pre-trigger

udevadm control --reload >/dev/null 2>&1 || :

export -p > /dracut-state.sh
exit 0
