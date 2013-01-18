#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

export DRACUT_SYSTEMD=1
if [ -f /dracut-state.sh ]; then
    . /dracut-state.sh 2>/dev/null
fi
type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh

source_conf /etc/conf.d

make_trace_mem "hook pre-trigger" "1:shortmem" "2+:mem" "3+:slab"
getargbool 0 rd.udev.info -n -y rdudevinfo && udevadm control --log-priority=info
getargbool 0 rd.udev.debug -n -y rdudevdebug && udevadm control --log-priority=debug
udevproperty "hookdir=$hookdir"

source_hook pre-trigger

udevadm control --reload >/dev/null 2>&1 || :

export -p > /dracut-state.sh
exit 0
