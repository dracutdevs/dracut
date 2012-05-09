#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

exec </dev/console >/dev/console 2>&1
if [ -f /dracut-state.sh ]; then
    . /dracut-state.sh || :
fi
. /lib/dracut-lib.sh
source_conf /etc/conf.d

# pre pivot scripts are sourced just before we doing cleanup and switch over
# to the new root.
getarg 'rd.break=pre-udev' 'rdbreak=pre-udev' && emergency_shell -n pre-udev "Break pre-udev"
source_hook pre-udev

export -p > /dracut-state.sh
