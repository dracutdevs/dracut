#!/bin/sh

case "$root" in
  live:/dev/*)
    {
        printf 'KERNEL=="%s", RUN+="/sbin/initqueue --settled --onetime --unique /sbin/dmsquash-live-root $env{DEVNAME}"\n' \
            ${root#live:/dev/}
        printf 'SYMLINK=="%s", RUN+="/sbin/initqueue --settled --onetime --unique /sbin/dmsquash-live-root $env{DEVNAME}"\n' \
            ${root#live:/dev/}
    } >> /etc/udev/rules.d/99-live-squash.rules
    wait_for_dev -n "${root#live:}"
  ;;
  live:*)
    if [ -f "${root#live:}" ]; then
        /sbin/initqueue --settled --onetime --unique /sbin/dmsquash-live-root "${root#live:}"
    fi
  ;;
esac
