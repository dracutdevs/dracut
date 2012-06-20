#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

if [ -f /dracut-state.sh ]; then
    . /dracut-state.sh || :
fi
. /lib/dracut-lib.sh
source_conf /etc/conf.d

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
        && { flock -s 9 ; emergency_shell "Could not boot."; } 9>/.console_lock
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


export -p > /dracut-state.sh

systemctl isolate initrd-switch-root.target
