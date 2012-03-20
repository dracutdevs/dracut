#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
#
# Licensed under the GPLv2
#
# Copyright 2008-2010, Red Hat, Inc.
# Harald Hoyer <harald@redhat.com>
# Jeremy Katz <katzj@redhat.com>

export -p > /tmp/export.orig

NEWROOT="/sysroot"
[ -d $NEWROOT ] || mkdir -p -m 0755 $NEWROOT

OLDPATH=$PATH
PATH=/usr/sbin:/usr/bin:/sbin:/bin
export PATH

RD_DEBUG=""
. /lib/dracut-lib.sh
trap "emergency_shell Signal caught!" 0

[ -c /dev/null ] || mknod -m 0666 /dev/null c 1 3

# mount some important things
[ ! -d /proc/self ] && \
    mount -t proc -o nosuid,noexec,nodev proc /proc >/dev/null 2>&1

[ ! -d /sys/kernel ] && \
    mount -t sysfs -o nosuid,noexec,nodev sysfs /sys >/dev/null 2>&1

if [ -x /lib/systemd/systemd-timestamp ]; then
    RD_TIMESTAMP=$(/lib/systemd/systemd-timestamp)
else
    read RD_TIMESTAMP _tmp < /proc/uptime
    unset _tmp
fi

setdebug

if [ "$RD_DEBUG" = "yes" ]; then
    getarg quiet && DRACUT_QUIET="yes"
    a=$(getarg loglevel=)
    [ -n "$a" ] && [ $a -ge 8 ] && unset DRACUT_QUIET
fi

if ! ismounted /dev; then
    mount -t devtmpfs -o mode=0755,nosuid devtmpfs /dev >/dev/null 
fi

# prepare the /dev directory
[ ! -h /dev/fd ] && ln -s /proc/self/fd /dev/fd >/dev/null 2>&1
[ ! -h /dev/stdin ] && ln -s /proc/self/fd/0 /dev/stdin >/dev/null 2>&1
[ ! -h /dev/stdout ] && ln -s /proc/self/fd/1 /dev/stdout >/dev/null 2>&1
[ ! -h /dev/stderr ] && ln -s /proc/self/fd/2 /dev/stderr >/dev/null 2>&1

if ! ismounted /dev/pts; then
    mkdir -m 0755 /dev/pts
    mount -t devpts -o gid=5,mode=620,noexec,nosuid devpts /dev/pts >/dev/null 
fi

if ! ismounted /dev/shm; then
    mkdir -m 0755 /dev/shm
    mount -t tmpfs -o mode=1777,nosuid,nodev tmpfs /dev/shm >/dev/null 
fi

if ! ismounted /run; then
    mkdir -m 0755 /newrun
    mount -t tmpfs -o mode=0755,nosuid,nodev tmpfs /newrun >/dev/null 
    mv /run/* /newrun >/dev/null 2>&1
    mount --move /newrun /run
    rm -fr /newrun
fi

[ -d /run/initramfs ] || mkdir -p -m 0755 /run/initramfs

UDEVVERSION=$(udevadm --version)
if [ $UDEVVERSION -gt 166 ]; then
    # newer versions of udev use /run/udev/rules.d
    export UDEVRULESD=/run/udev/rules.d
    [ -d /run/udev ] || mkdir -p -m 0755 /run/udev
    [ -d $UDEVRULESD ] || mkdir -p -m 0755 $UDEVRULESD
else
    mkdir -m 0755 /dev/.udev /dev/.udev/rules.d
    export UDEVRULESD=/dev/.udev/rules.d
fi

if [ "$RD_DEBUG" = "yes" ]; then
    mkfifo /run/initramfs/loginit.pipe
    loginit $DRACUT_QUIET </run/initramfs/loginit.pipe >/dev/console 2>&1 &
    exec >/run/initramfs/loginit.pipe 2>&1
else
    exec 0<>/dev/console 1<>/dev/console 2<>/dev/console
fi

source_conf /etc/conf.d

# run scriptlets to parse the command line
getarg 'rd.break=cmdline' 'rdbreak=cmdline' && emergency_shell -n cmdline "Break before cmdline"
source_hook cmdline

[ -z "$root" ] && die "No or empty root= argument"
[ -z "$rootok" ] && die "Don't know how to handle 'root=$root'"

export root rflags fstype netroot NEWROOT

# pre-udev scripts run before udev starts, and are run only once.
getarg 'rd.break=pre-udev' 'rdbreak=pre-udev' && emergency_shell -n pre-udev "Break before pre-udev"
source_hook pre-udev

# start up udev and trigger cold plugs
udevd --daemon --resolve-names=never

UDEV_LOG_PRIO_ARG=--log-priority
UDEV_QUEUE_EMPTY="udevadm settle --timeout=0"

if [ $UDEVVERSION -lt 140 ]; then
    UDEV_LOG_PRIO_ARG=--log_priority
    UDEV_QUEUE_EMPTY="udevadm settle --timeout=1"
fi

getargbool 0 rd.udev.info -y rdudevinfo && udevadm control "$UDEV_LOG_PRIO_ARG=info"
getargbool 0 rd.udev.debug -y rdudevdebug && udevadm control "$UDEV_LOG_PRIO_ARG=debug"
udevproperty "hookdir=$hookdir"

getarg 'rd.break=pre-trigger' 'rdbreak=pre-trigger' && emergency_shell -n pre-trigger "Break before pre-trigger"
source_hook pre-trigger

udevadm control --reload >/dev/null 2>&1 || :
# then the rest
udevadm trigger --type=subsystems --action=add >/dev/null 2>&1
udevadm trigger --type=devices --action=add >/dev/null 2>&1

getarg 'rd.break=initqueue' 'rdbreak=initqueue' && emergency_shell -n initqueue "Break before initqueue"

RDRETRY=$(getarg rd.retry 'rd_retry=')
RDRETRY=${RDRETRY:-20}
RDRETRY=$(($RDRETRY*2))
export RDRETRY
main_loop=0
export main_loop
while :; do

    check_finished && break

    udevsettle

    check_finished && break

    if [ -f $hookdir/initqueue/work ]; then
        rm $hookdir/initqueue/work
    fi

    for job in $hookdir/initqueue/*.sh; do
        [ -e "$job" ] || break
        job=$job . $job
        check_finished && break 2
    done

    $UDEV_QUEUE_EMPTY >/dev/null 2>&1 || continue

    for job in $hookdir/initqueue/settled/*.sh; do
        [ -e "$job" ] || break
        job=$job . $job
        check_finished && break 2
    done

    $UDEV_QUEUE_EMPTY >/dev/null 2>&1 || continue

    # no more udev jobs and queues empty.
    sleep 0.5


    if [ $main_loop -gt $(($RDRETRY/2)) ]; then
        for job in $hookdir/initqueue/timeout/*.sh; do
            [ -e "$job" ] || break
            job=$job . $job
            main_loop=0
        done
    fi

    main_loop=$(($main_loop+1))
    [ $main_loop -gt $RDRETRY ] \
        && { flock -s 9 ; emergency_shell "Unable to process initqueue"; } 9>/.console_lock
done
unset job
unset queuetriggered
unset main_loop
unset RDRETRY

# pre-mount happens before we try to mount the root filesystem,
# and happens once.
getarg 'rd.break=pre-mount' 'rdbreak=pre-mount' && emergency_shell -n pre-mount "Break pre-mount"
source_hook pre-mount


getarg 'rd.break=mount' 'rdbreak=mount' && emergency_shell -n mount "Break mount"
# mount scripts actually try to mount the root filesystem, and may
# be sourced any number of times. As soon as one suceeds, no more are sourced.
i=0
while :; do
    if ismounted "$NEWROOT"; then
        usable_root "$NEWROOT" && break;
        umount "$NEWROOT"
    fi
    for f in $hookdir/mount/*.sh; do
        [ -f "$f" ] && . "$f"
        if ismounted "$NEWROOT"; then
            usable_root "$NEWROOT" && break;
            warn "$NEWROOT has no proper rootfs layout, ignoring and removing offending mount hook"
            umount "$NEWROOT"
            rm -f "$f"
        fi
    done

    i=$(($i+1))
    [ $i -gt 20 ] \
        && { flock -s 9 ; emergency_shell "Can't mount root filesystem"; } 9>/.console_lock
done

{
    echo -n "Mounted root filesystem "
    while read dev mp rest; do [ "$mp" = "$NEWROOT" ] && echo $dev; done < /proc/mounts
} | vinfo

# pre pivot scripts are sourced just before we switch over to the new root.
getarg 'rd.break=pre-pivot' 'rdbreak=pre-pivot' && emergency_shell -n pre-pivot "Break pre-pivot"
source_hook pre-pivot

# By the time we get here, the root filesystem should be mounted.
# Try to find init. 
for i in "$(getarg real_init=)" "$(getarg init=)" $(getargs rd.distroinit=) /sbin/init; do
    [ -n "$i" ] || continue

    __p=$(readlink -f "${NEWROOT}/${i}")
    if [ -x "$__p" ]; then
        INIT="$i"
        break
    fi
done

[ "$INIT" ] || {
    echo "Cannot find init!"
    echo "Please check to make sure you passed a valid root filesystem!"
    emergency_shell
}


if [ $UDEVVERSION -lt 168 ]; then
    # stop udev queue before killing it
    udevadm control --stop-exec-queue

    HARD=""
    while pidof udevd >/dev/null 2>&1; do
        for pid in $(pidof udevd); do
            kill $HARD $pid >/dev/null 2>&1
        done
        HARD="-9"
    done
else
    udevadm control --exit
    udevadm info --cleanup-db
fi

export RD_TIMESTAMP
export -n root rflags fstype netroot NEWROOT
set +x # Turn off debugging for this section
# Clean up the environment
for i in $(export -p); do
    i=${i#declare -x}
    i=${i#export}
    strstr "$i" "=" || continue
    i=${i%%=*}
    [ -z "$i" ] && continue
    case $i in
        root|PATH|HOME|TERM|PS4|RD_*)
            :;;
        *)
            unset "$i";;
    esac
done
. /tmp/export.orig 2>/dev/null || :
rm -f /tmp/export.orig

initargs=""
read CLINE </proc/cmdline
if getarg init= >/dev/null ; then
    set +x # Turn off debugging for this section
    ignoreargs="console BOOT_IMAGE"
    # only pass arguments after init= to the init
    CLINE=${CLINE#*init=}
    set -- $CLINE
    shift # clear out the rest of the "init=" arg
    for x in "$@"; do
        for s in $ignoreargs; do
            [ "${x%%=*}" = $s ] && continue 2
        done
        initargs="$initargs $x"
    done
    unset CLINE
else
    set +x # Turn off debugging for this section
    set -- $CLINE
    for x in "$@"; do
        case "$x" in
            [0-9]|s|S|single|emergency|auto ) \
                initargs="$initargs $x"
                ;;
        esac
    done
fi
[ "$RD_DEBUG" = "yes" ] && set -x

if ! [ -d "$NEWROOT"/run ]; then
    NEWRUN=/dev/.initramfs
    mkdir -m 0755 "$NEWRUN"
    mount --rbind /run/initramfs "$NEWRUN"
fi

wait_for_loginit

# remove helper symlink
[ -h /dev/root ] && rm -f /dev/root

getarg rd.break rdbreak && emergency_shell -n switch_root "Break before switch_root"
info "Switching root"

source_hook cleanup

unset PS4

CAPSH=$(command -v capsh)
SWITCH_ROOT=$(command -v switch_root)
PATH=$OLDPATH
export PATH

if [ -f /etc/capsdrop ]; then
    . /etc/capsdrop
    info "Calling $INIT with capabilities $CAPS_INIT_DROP dropped."
    unset RD_DEBUG
    exec $CAPSH --drop="$CAPS_INIT_DROP" -- \
        -c "exec switch_root \"$NEWROOT\" \"$INIT\" $initargs" || \
    {
	warn "Command:"
	warn capsh --drop=$CAPS_INIT_DROP -- -c exec switch_root "$NEWROOT" "$INIT" $initargs
	warn "failed."
	emergency_shell
    }
else
    unset RD_DEBUG
    exec $SWITCH_ROOT "$NEWROOT" "$INIT" $initargs || {
	warn "Something went very badly wrong in the initramfs.  Please "
	warn "file a bug against dracut."
	emergency_shell
    }
fi
