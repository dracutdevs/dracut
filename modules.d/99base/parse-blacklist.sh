#!/bin/sh

if getarg rdblacklist= >/dev/null ; then
    [ "$CMDLINE" ] || read CMDLINE < /proc/cmdline
    for p in $CMDLINE; do
        [ -n "${p%rdblacklist=*}" ] && continue

        echo "blacklist ${p#rdblacklist=}" >> /etc/modprobe.d/initramfsblacklist.conf
    done
fi
