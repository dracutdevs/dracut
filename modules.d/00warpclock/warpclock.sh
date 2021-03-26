#!/bin/sh

if test -e /etc/adjtime; then
    while read -r line; do
        if test "$line" = LOCAL; then
            hwclock --systz
        fi
    done < /etc/adjtime
fi
