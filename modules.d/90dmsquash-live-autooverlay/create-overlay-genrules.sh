#!/bin/sh

case "$root" in
    live:/dev/*)
        printf 'SYMLINK=="%s", RUN+="/sbin/initqueue --settled --onetime --unique /sbin/create-overlay %s"\n' \
            "${root#live:/dev/}" "${root#live:}" >> /etc/udev/rules.d/95-create-overlay.rules
        wait_for_dev -n "${root#live:}"
        ;;
esac
