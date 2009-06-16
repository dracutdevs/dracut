#!/bin/sh

# Don't continue if we don't need network
[ -z "$netroot" ] && return;

# Write udev rules
{
    printf 'ACTION=="add", SUBSYSTEM=="net", RUN+="/sbin/ifup $env{INTERFACE}"\n'
    printf 'ACTION=="online", SUBSYSTEM=="net", RUN+="/sbin/netroot $env{INTERFACE}"\n'
} > /etc/udev/rules.d/60-net.rules
