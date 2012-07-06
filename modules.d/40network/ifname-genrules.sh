#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

# if there are no ifname parameters, just use NAME=KERNEL
if ! getarg ifname= >/dev/null ; then
    return
fi

command -v parse_ifname_opts >/dev/null || . /lib/net-lib.sh

{
    for p in $(getargs ifname=); do
        parse_ifname_opts $p
        printf 'SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="%s", ATTR{type}=="1", NAME="%s"\n' "$ifname_mac" "$ifname_if"
    done

} >> /etc/udev/rules.d/80-ifname.rules
