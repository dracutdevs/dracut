#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
#
# Licensed under the GPLv2
#
# Copyright 2011, Red Hat, Inc.
# Harald Hoyer <harald@redhat.com>
ACTION="$1"

export TERM=linux
export PATH=/usr/sbin:/usr/bin:/sbin:/bin
. /lib/dracut-lib.sh

# if "kexec" was installed after creating the initramfs, we try to copy it from the real root
# libz normally is pulled in via kmod/modprobe and udevadm
if [ "$ACTION" = "kexec" ] && ! command -v kexec >/dev/null 2>&1; then
    for p in /usr/sbin /usr/bin /sbin /bin; do
        cp -a /oldroot/${p}/kexec $p >/dev/null 2>&1 && break
    done
    hash kexec
fi

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

while _check_shutdown; do
:
done
_check_shutdown final

getarg 'rd.break=shutdown' && emergency_shell --shutdown shutdown "Break before shutdown"

case "$ACTION" in
    reboot|poweroff|halt)
        $ACTION -f -d -n
        warn "$ACTION failed!"
        ;;
    kexec)
        kexec -e
        warn "$ACTION failed!"
        ;;
    *)
        warn "Shutdown called with argument '$ACTION'. Rebooting!"
        reboot -f -d -n
        ;;
esac

emergency_shell --shutdown shutdown
