#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

[ -z "$UDEVVERSION" ] && export UDEVVERSION=$(udevadm --version)

for f in /etc/udev/rules.d/*-persistent-storage.rules; do
    [ -e "$f" ] || continue
    while read line; do
        if [ "${line%%IMPORT PATH_ID}" != "$line" ]; then
            if [ $UDEVVERSION -ge 174 ]; then
                printf '%sIMPORT{builtin}="path_id"\n' "${line%%IMPORT PATH_ID}"
            else
                printf '%sIMPORT{program}="path_id %%p"\n' "${line%%IMPORT PATH_ID}"
            fi
        elif [ "${line%%IMPORT BLKID}" != "$line" ]; then
            if [ $UDEVVERSION -ge 176 ]; then
                printf '%sIMPORT{builtin}="blkid"\n' "${line%%IMPORT BLKID}"
            else
                printf '%sIMPORT{program}="/sbin/blkid -o udev -p $tempnode"\n' "${line%%IMPORT BLKID}"
            fi
        else
            echo "$line"
        fi
    done < "${f}" > "${f}.new"
    mv "${f}.new" "$f"
done
