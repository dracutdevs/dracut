#!/bin/sh
# This file is part of dracut warpclock module.
# SPDX-License-Identifier: GPL-2.0-or-later

# Set the kernel's timezone and reset the system time
# if adjtime is set to LOCAL.

if test -e /etc/adjtime; then
    while read -r line; do
        if test "$line" = LOCAL; then
            hwclock --systz
        fi
    done < /etc/adjtime
fi
