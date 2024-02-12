#!/bin/sh
#
# Licensed under the GPLv2
#
# Copyright 2011, Red Hat, Inc.
# Harald Hoyer <harald@redhat.com>
ACTION="$1"

# Before trying to use /dev/console, verify that it exists,
# and that it can actually be used. When console=null is used,
# echo will fail. We do the check in a subshell, because otherwise
# the process will be killed when when running as PID 1.
# shellcheck disable=SC2217
[ -w /dev/console ] \
    && (echo < /dev/console > /dev/null 2> /dev/null) \
    && exec < /dev/console >> /dev/console 2>> /dev/console

export TERM=linux
export PATH=/usr/sbin:/usr/bin:/sbin:/bin
. /lib/dracut-lib.sh

if [ "$(stat -c '%T' -f /)" = "tmpfs" ]; then
    mount -o remount,rw /
fi

mkdir -p /oldsys
for i in sys proc run dev; do
    mkdir -p /oldsys/$i
    mount --move /oldroot/$i /oldsys/$i
done

# if "kexec" was installed after creating the initramfs, we try to copy it from the real root
# libz normally is pulled in via kmod/modprobe and udevadm
if [ "$ACTION" = "kexec" ] && ! command -v kexec > /dev/null 2>&1; then
    for p in /usr/sbin /usr/bin /sbin /bin; do
        cp -a /oldroot/${p}/kexec $p > /dev/null 2>&1 && break
    done
    hash kexec
fi

trap "emergency_shell --shutdown shutdown Signal caught!" 0
getargs 'rd.break=pre-shutdown' && emergency_shell --shutdown pre-shutdown "Break before pre-shutdown"

source_hook pre-shutdown

warn "Killing all remaining processes"

killall_proc_mountpoint /oldroot || sleep 0.2

# Timeout for umount calls. The value can be set to 0 to wait forever.
_umount_timeout=$(getarg rd.shutdown.timeout.umount)
_umount_timeout=${_umount_timeout:-90s}
_timed_out_umounts=""

umount_a() {
    local _verbose="n"
    if [ "$1" = "-v" ]; then
        _verbose="y"
        shift
        exec 7>&2
    else
        exec 7> /dev/null
    fi

    local _did_umount="n"
    while read -r _ mp _ || [ -n "$mp" ]; do
        strstr "$mp" oldroot || continue
        strstr "$_timed_out_umounts" " $mp " && continue

        # Unmount the file system. The operation uses a timeout to avoid waiting
        # indefinitely if this is e.g. a stuck NFS mount. The command is
        # invoked in a subshell to silence also the "Killed" message that might
        # be produced by the shell.
        (
            set +m
            timeout --signal=KILL "$_umount_timeout" umount "$mp"
        ) 2>&7
        local ret=$?
        if [ $ret -eq 0 ]; then
            _did_umount="y"
            warn "Unmounted $mp."
        elif [ $ret -eq 137 ]; then
            _timed_out_umounts="$_timed_out_umounts $mp "
            warn "Unmounting $mp timed out."
        elif [ "$_verbose" = "y" ]; then
            warn "Unmounting $mp failed with status $ret."
        fi
    done < /proc/mounts

    losetup -D 2>&7

    exec 7>&-
    [ "$_did_umount" = "y" ] && return 0
    return 1
}

_cnt=0
while [ $_cnt -le 40 ]; do
    umount_a || break
    _cnt=$((_cnt + 1))
done

[ $_cnt -ge 40 ] && umount_a -v

if strstr "$(cat /proc/mounts)" "/oldroot"; then
    warn "Cannot umount /oldroot"
    for _pid in /proc/*; do
        _pid=${_pid##/proc/}
        case $_pid in
            *[!0-9]*) continue ;;
        esac
        [ "$_pid" -eq $$ ] && continue

        [ -e "/proc/$_pid/exe" ] || continue
        [ -e "/proc/$_pid/root" ] || continue

        if strstr "$(ls -l /proc/"$_pid" /proc/"$_pid"/fd 2> /dev/null)" "oldroot"; then
            warn "Blocking umount of /oldroot [$_pid] $(cat /proc/"$_pid"/cmdline)"
        else
            warn "Still running [$_pid] $(cat /proc/"$_pid"/cmdline)"
        fi

        # shellcheck disable=SC2012
        ls -l "/proc/$_pid/exe" 2>&1 | vwarn
        # shellcheck disable=SC2012
        ls -l "/proc/$_pid/fd" 2>&1 | vwarn
    done
fi

_check_shutdown() {
    local __f
    local __s=0
    for __f in "$hookdir"/shutdown/*.sh; do
        [ -e "$__f" ] || continue
        # shellcheck disable=SC1090 disable=SC2240
        if (final="$1" . "$__f" "$1"); then
            rm -f -- "$__f"
        else
            __s=1
        fi
    done
    return $__s
}

_cnt=0
while [ $_cnt -le 40 ]; do
    _check_shutdown && break
    _cnt=$((_cnt + 1))
done
[ $_cnt -ge 40 ] && _check_shutdown final

if type plymouth > /dev/null 2>&1; then
    plymouth --hide-splash
elif [ -x /oldroot/bin/plymouth ]; then
    /oldroot/bin/plymouth --hide-splash
fi

getargs 'rd.break=shutdown' && emergency_shell --shutdown shutdown "Break before shutdown"

case "$ACTION" in
    reboot | poweroff | halt)
        $ACTION -f -n
        warn "$ACTION failed!"
        ;;
    kexec)
        kexec -e
        warn "$ACTION failed!"
        reboot -f -n
        ;;
    *)
        warn "Shutdown called with argument '$ACTION'. Rebooting!"
        reboot -f -n
        ;;
esac

emergency_shell --shutdown shutdown
