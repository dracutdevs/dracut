#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
#
# Licensed under the GPLv2
#
# Copyright 2011, Red Hat, Inc.
# Harald Hoyer <harald@redhat.com>
ACTION="$1"

[ -w /dev/console ] && exec </dev/console >>/dev/console 2>>/dev/console

export TERM=linux
export PATH=/usr/sbin:/usr/bin:/sbin:/bin
. /lib/dracut-lib.sh

if [ "$(stat -c '%T' -f /)" = "tmpfs" ]; then
    mount -o remount,rw /
fi

mkdir /oldsys
for i in sys proc run dev; do
    mkdir /oldsys/$i
    mount --move /oldroot/$i /oldsys/$i
done

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

source_hook pre-shutdown

warn "Killing all remaining processes"

killall_proc_mountpoint /oldroot

umount_a() {
    local _did_umount="n"
    while read a mp a; do
        if strstr "$mp" oldroot; then
            if umount "$mp"; then
                _did_umount="y"
                warn "Unmounted $mp."
            fi
        fi
    done </proc/mounts
    losetup -D
    [ "$_did_umount" = "y" ] && return 0
    return 1
}

_cnt=0
while [ $_cnt -le 40 ]; do
    umount_a 2>/dev/null || break
    _cnt=$(($_cnt+1))
done

[ $_cnt -ge 40 ] && umount_a

if strstr "$(cat /proc/mounts)" "/oldroot"; then
    warn "Cannot umount /oldroot"
    for _pid in /proc/*; do
        _pid=${_pid##/proc/}
        case $_pid in
            *[!0-9]*) continue;;
        esac
        [ $_pid -eq $$ ] && continue

        [ -e "/proc/$_pid/exe" ] || continue
        [ -e "/proc/$_pid/root" ] || continue

        if strstr "$(ls -l /proc/$_pid /proc/$_pid/fd 2>/dev/null)" "oldroot"; then
            warn "Blocking umount of /oldroot [$_pid] $(cat /proc/$_pid/cmdline)"
        else
            warn "Still running [$_pid] $(cat /proc/$_pid/cmdline)"
        fi

        ls -l "/proc/$_pid/exe" 2>&1 | vwarn
        ls -l "/proc/$_pid/fd" 2>&1 | vwarn
    done
fi

_check_shutdown() {
    local __f
    local __s=1
    for __f in $hookdir/shutdown/*.sh; do
        [ -e "$__f" ] || continue
        ( . "$__f" $1 )
        if [ $? -eq 0 ]; then
            rm -f -- $__f
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
        reboot -f -d -n
        ;;
    *)
        warn "Shutdown called with argument '$ACTION'. Rebooting!"
        reboot -f -d -n
        ;;
esac

emergency_shell --shutdown shutdown
