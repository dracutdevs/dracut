#!/bin/sh

export DRACUT_SYSTEMD=1
if [ -f /dracut-state.sh ]; then
    . /dracut-state.sh 2> /dev/null
fi
type getarg > /dev/null 2>&1 || . /lib/dracut-lib.sh

source_conf /etc/conf.d

make_trace_mem "hook initqueue" '1:shortmem' '2+:mem' '3+:slab'
getargs 'rd.break=initqueue' -d 'rdbreak=initqueue' && emergency_shell -n initqueue "Break before initqueue"

RDRETRY=$(getarg rd.retry -d 'rd_retry=')
RDRETRY=${RDRETRY:-180}
RDRETRY=$((RDRETRY * 2))
export RDRETRY

main_loop=0
export main_loop

while :; do

    check_finished && break

    udevadm settle --exit-if-exists="$hookdir"/initqueue/work

    check_finished && break

    if [ -f "$hookdir"/initqueue/work ]; then
        rm -f -- "$hookdir/initqueue/work"
    fi

    for job in "$hookdir"/initqueue/*.sh; do
        [ -e "$job" ] || break
        # shellcheck disable=SC2097 disable=SC1090 disable=SC2098
        job=$job . "$job"
        check_finished && break 2
    done

    udevadm settle --timeout=0 > /dev/null 2>&1 || continue

    for job in "$hookdir"/initqueue/settled/*.sh; do
        [ -e "$job" ] || break
        # shellcheck disable=SC2097 disable=SC1090 disable=SC2098
        job=$job . "$job"
        check_finished && break 2
    done

    udevadm settle --timeout=0 > /dev/null 2>&1 || continue

    # no more udev jobs and queues empty.
    sleep 0.5

    for i in /run/systemd/ask-password/ask.*; do
        [ -e "$i" ] && continue 2
    done

    if [ $main_loop -gt $((2 * RDRETRY / 3)) ]; then
        warn "dracut-initqueue: timeout, still waiting for following initqueue hooks:"
        for _f in "$hookdir"/initqueue/finished/*.sh; do
            warn "$_f: \"$(cat "$_f")\""
        done
        if [ "$(ls -A "$hookdir"/initqueue/finished)" ]; then
            warn "dracut-initqueue: starting timeout scripts"
            for job in "$hookdir"/initqueue/timeout/*.sh; do
                [ -e "$job" ] || break
                # shellcheck disable=SC2097 disable=SC1090 disable=SC2098
                job=$job . "$job"
                udevadm settle --timeout=0 > /dev/null 2>&1 || main_loop=0
                [ -f "$hookdir"/initqueue/work ] && main_loop=0
                [ $main_loop -eq 0 ] && break
            done
        fi
    fi

    main_loop=$((main_loop + 1))
    if [ $main_loop -gt $RDRETRY ]; then
        if ! [ -f /sysroot/etc/fstab ] || ! [ -e /sysroot/sbin/init ]; then
            emergency_shell "Could not boot."
        fi
        warn "Not all disks have been found."
        warn "You might want to regenerate your initramfs."
        break
    fi
done

unset job
unset queuetriggered
unset main_loop
unset RDRETRY

export -p > /dracut-state.sh

exit 0
