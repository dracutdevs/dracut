#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
if [ "${root%%:*}" = "live" ]; then
    {
        printf 'KERNEL=="%s", SYMLINK+="live"\n' \
            ${root#live:/dev/} 
        printf 'SYMLINK=="%s", SYMLINK+="live"\n' \
            ${root#live:/dev/} 
    } >> /dev/.udev/rules.d/99-live-mount.rules
    {
        printf 'KERNEL=="%s", RUN+="/sbin/initqueue --settled --onetime --unique /sbin/dmsquash-live-root $env{DEVNAME}"\n' \
            ${root#live:/dev/} 
        printf 'SYMLINK=="%s", RUN+="/sbin/initqueue --settled --onetime --unique /sbin/dmsquash-live-root $env{DEVNAME}"\n' \
            ${root#live:/dev/} 
    } >> /etc/udev/rules.d/99-live-squash.rules
    echo '[ -e /dev/root ]' > /initqueue-finished/dmsquash.sh
fi
