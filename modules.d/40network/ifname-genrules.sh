#!/bin/sh

# if there are no ifname parameters, just use NAME=KERNEL
if ! getarg ifname= >/dev/null ; then
    echo 'SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="?*", ATTR{type}=="1", NAME="%k"' \
        > /etc/udev/rules.d/50-ifname.rules
    return
fi

{
    for p in $(getargs ifname=); do
        parse_ifname_opts $p
	printf 'SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="%s", ATTR{type}=="1", NAME="%s"\n' "$ifname_mac" "$ifname_if"
    done

    # Rename non named interfaces out of the way for named ones.
    for p in $(getargs ifname=); do
        parse_ifname_opts $p
	printf 'SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="?*", ATTR{type}=="1", NAME!="?*", KERNEL=="%s", NAME="%%k-renamed"\n' "$ifname_if"
    done
} > /etc/udev/rules.d/50-ifname.rules
