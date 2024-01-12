#!/bin/bash

type getcmdline > /dev/null 2>&1 || . /lib/dracut-lib.sh
type source_hook > /dev/null 2>&1 || . /lib/dracut-lib.sh

nm_generate_connections() {
    rm -f /run/NetworkManager/system-connections/*
    if [ -x /usr/libexec/nm-initrd-generator ]; then
        # shellcheck disable=SC2046
        /usr/libexec/nm-initrd-generator -- $(getcmdline)
    elif [ -x /usr/lib/nm-initrd-generator ]; then
        # shellcheck disable=SC2046
        /usr/lib/nm-initrd-generator -- $(getcmdline)
    else
        warn "nm-initrd-generator not found"
    fi

    if getargbool 0 rd.neednet; then
        for i in /usr/lib/NetworkManager/system-connections/* \
            /run/NetworkManager/system-connections/* \
            /etc/NetworkManager/system-connections/* \
            /etc/sysconfig/network-scripts/ifcfg-*; do
            [ -f "$i" ] || continue
            #on machines with systemd, nm-wait-online is ordered before the initqueue,
            #so there is no need to do the nm.done check. Even if something fails,
            #there is nothing in initqueue to wait for.
            if [ -z "$DRACUT_SYSTEMD" ]; then
                mkdir -p "$hookdir"/initqueue/finished
                echo '[ -f /tmp/nm.done ]' > "$hookdir"/initqueue/finished/nm.sh
            fi
            mkdir -p /run/NetworkManager/initrd
            : > /run/NetworkManager/initrd/neednet # activate NM services
            break
        done
    fi
}

nm_reload_connections() {
    [ -n "$DRACUT_SYSTEMD" ] && systemctl is-active nm-initrd.service && nmcli connection reload
}

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

nm_call_hooks() {
    ifname="$1"
    [ -n "$ifname" ] || return 1
    state="/run/NetworkManager/devices/"$(cat /sys/class/net/"${ifname}"/ifindex)
    dhcpopts_create "$state" > /tmp/dhclient."$ifname".dhcpopts
    source_hook initqueue/online "$ifname"
    /sbin/netroot "$ifname"
}
