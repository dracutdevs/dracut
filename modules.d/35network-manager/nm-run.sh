#!/bin/bash

type source_hook > /dev/null 2>&1 || . /lib/dracut-lib.sh

if [ -e /tmp/nm.done ]; then
    return
fi

if [ -z "$DRACUT_SYSTEMD" ]; then
    # Only start NM if networking is needed
    if [ -e /run/NetworkManager/initrd/neednet ]; then
        for i in /usr/lib/NetworkManager/system-connections/* \
            /run/NetworkManager/system-connections/* \
            /etc/NetworkManager/system-connections/* \
            /etc/sysconfig/network-scripts/ifcfg-*; do
            [ -f "$i" ] || continue
            /usr/sbin/NetworkManager --configure-and-quit=initrd --no-daemon
            break
        done
    fi
fi

if [ -s /run/NetworkManager/initrd/hostname ]; then
    cat /run/NetworkManager/initrd/hostname > /proc/sys/kernel/hostname
fi

kf_get_string() {
    # NetworkManager writes keyfiles (glib's GKeyFile API). Have a naive
    # parser for it.
    #
    # But GKeyFile will backslash escape certain keys (\s, \t, \n) but also
    # escape backslash. As an approximation, interpret the string with printf's
    # '%b'.
    #
    # This is supposed to mimic g_key_file_get_string() (poorly).

    v1="$(sed -n "s/^$1=/=/p" | sed '1!d')"
    test "$v1" = "${v1#=}" && return 1
    printf "%b" "${v1#=}"
}

kf_unescape() {
    # Another layer of unescaping. While values in GKeyFile format
    # are backslash escaped, the original strings (which are in no
    # defined encoding) are backslash escaped too to be valid UTF-8.
    # This will undo the second layer of escaping to give binary "strings".
    printf "%b" "$1"
}

kf_parse() {
    v3="$(kf_get_string "$1")" || return 1
    v3="$(kf_unescape "$v3")"
    printf '%s=%s\n' "$2" "$(printf '%q' "$v3")"
}

dhcpopts_create() {
    kf_parse root-path new_root_path < "$1"
    kf_parse next-server new_next_server < "$1"
    kf_parse dhcp-bootfile filename < "$1"
}

for _i in /sys/class/net/*; do
    state="/run/NetworkManager/devices/$(cat "$_i"/ifindex)"
    grep -q '^connection-uuid=' "$state" 2> /dev/null || continue
    ifname="${_i##*/}"
    dhcpopts_create "$state" > /tmp/dhclient."$ifname".dhcpopts
    source_hook initqueue/online "$ifname"
    /sbin/netroot "$ifname"
done

: > /tmp/nm.done
