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
getarg 'rd.break=pre-pivot' 'rdbreak=pre-pivot' && emergency_shell -n pre-pivot "Break pre-pivot"
source_hook pre-pivot

# pre pivot cleanup scripts are sourced just before we switch over to the new root.
getarg 'rd.break=cleanup' 'rdbreak=cleanup' && emergency_shell -n cleanup "Break cleanup"
source_hook cleanup

# By the time we get here, the root filesystem should be mounted.
# Try to find init. 

for i in "$(getarg real_init=)" "$(getarg init=)"; do
    [ -n "$i" ] || continue

    __p=$(readlink -f "${NEWROOT}/${i}")
    if [ -x "$__p" ]; then
        INIT="$i"
        echo "NEWINIT=\"$INIT\"" > /run/initramfs/switch-root.conf
        break
    fi
done

echo "NEWROOT=\"$NEWROOT\"" >> /run/initramfs/switch-root.conf

udevadm control --stop-exec-queue
systemctl stop systemd-udev.service
udevadm info --cleanup-db

# remove helper symlink
[ -h /dev/root ] && rm -f /dev/root

getarg rd.break rdbreak && emergency_shell -n switch_root "Break before switch_root"
info "Switching root"

export -p > /dracut-state.sh
