#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
#
# Licensed under the GPLv2
#
# Copyright 2011, Red Hat, Inc.
# Harald Hoyer <harald@redhat.com>

#!/bin/sh
. /lib/dracut-lib.sh
export TERM=linux
PATH=/usr/sbin:/usr/bin:/sbin:/bin

trap "emergency_shell --shutdown shutdown Signal caught!" 0
getarg 'rd.break=pre-shutdown' && emergency_shell --shutdown pre-shutdown "Break before pre-shutdown"

umount_a() {
    local _did_umount="n"
    while read a mp a; do
        if strstr "$mp" oldroot; then
            if umount "$mp"; then
                _did_umount="y"
                echo "Unmounted $mp."
            fi
        fi
    done </proc/mounts
    [ "$_did_umount" = "y" ] && return 0
    return 1
}

_cnt=0
while [ $_cnt -le 40 ]; do
    umount_a 2>/dev/null || break
    _cnt=$(($_cnt+1))
done
[ $_cnt -ge 40 ] && umount_a

_check_shutdown() {
    local __f
    local __s=1
    for __f in $hookdir/shutdown/*.sh; do
        [ -e "$__f" ] || continue
        ( . "$__f" $1 ) 
        if [ $? -eq 0 ]; then 
            rm -f $__f
            __s=0
        fi
    done
    return $__s
}

_cnt=0
while _check_shutdown; do
:
done
_check_shutdown final

getarg 'rd.break=shutdown' && emergency_shell --shutdown shutdown "Break before shutdown"
[ "$1" = "reboot" ] && reboot -f -d -n --no-wall
[ "$1" = "poweroff" ] && poweroff -f -d -n --no-wall
[ "$1" = "halt" ] && halt -f -d -n --no-wall
[ "$1" = "kexec" ] && kexec -e
