#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
if [ "${root%%:*}" = "liveiso" ]; then
    {
        printf 'KERNEL=="loop-control", RUN+="/sbin/initqueue --settled --onetime --unique /sbin/dmsquash-live-root `/sbin/losetup -f --show %s`"\n' \
            ${root#liveiso:}
    } >> /etc/udev/rules.d/99-liveiso-mount.rules
fi
