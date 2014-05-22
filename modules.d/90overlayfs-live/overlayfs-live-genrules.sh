#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
case "$root" in
  live:/dev/*)
        break
  ;;
  live:*)
    if [ -f "${root#live:}" ]; then
        /sbin/initqueue --settled --onetime --unique /sbin/overlayfs-live-root "${root#live:}"
    fi
  ;;
esac
