#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
# close everything which is not busy
rm -f -- /etc/udev/rules.d/70-luks.rules >/dev/null 2>&1

if ! getarg rd.luks.uuid -d rd_LUKS_UUID >/dev/null 2>&1 && getargbool 1 rd.luks -d -n rd_NO_LUKS >/dev/null 2>&1; then
    while true; do
        local do_break="y"
        for i in /dev/mapper/luks-*; do
            cryptsetup luksClose $i >/dev/null 2>&1 && do_break=n
        done
        [ "$do_break" = "y" ] && break
    done
fi
