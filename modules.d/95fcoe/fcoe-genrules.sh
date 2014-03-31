#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

# We use (fcoe_interface or fcoe_mac) and fcoe_dcb as set by parse-fcoe.sh
# If neither mac nor interface are set we don't continue
[ -z "$fcoe_interface" -a -z "$fcoe_mac" ] && return

# Write udev rules
{
    if [ -n "$fcoe_mac" ] ; then
        printf 'ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="%s", RUN+="/sbin/initqueue --onetime --unique --name fcoe-up-$env{INTERFACE} /sbin/fcoe-up $env{INTERFACE} %s"\n' "$fcoe_mac" "$fcoe_dcb"
    else
        printf 'ACTION=="add", SUBSYSTEM=="net", NAME=="%s", RUN+="/sbin/initqueue --onetime --unique --name fcoe-up-$env{INTERFACE} /sbin/fcoe-up $env{INTERFACE} %s"\n' "$fcoe_interface" "$fcoe_dcb"
    fi
} >> /etc/udev/rules.d/92-fcoe.rules
