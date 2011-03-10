#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
case "$root" in
  live:/dev/*)
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
    } >> $UDEVRULESD/99-live-squash.rules
    echo '[ -e /dev/root ]' > /initqueue-finished/dmsquash.sh
  ;;
  live:*)
    if [ -f "${root#live:}" ]; then
        /sbin/initqueue --settled --onetime --unique /sbin/dmsquash-live-root "${root#live:}"
        echo '[ -e /dev/root ]' > /initqueue-finished/dmsquash.sh
    fi
  ;;
esac
