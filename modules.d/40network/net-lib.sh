#!/bin/bash

get_ip() {
    local iface="$1" ip=""
    ip=$(ip -o -f inet addr show $iface)
    ip=${ip%%/*}
    ip=${ip##* }
}

iface_for_remote_addr() {
    set -- $(ip -o route get to $1)
    echo $5
}

iface_for_mac() {
    local interface="" mac="$(echo $1 | tr '[:upper:]' '[:lower:]')"
    for interface in /sys/class/net/*; do
        if [ $(cat $interface/address) = "$mac" ]; then
            echo ${interface##*/}
        fi
    done
}

iface_has_link() {
    local interface="$1" flags=""
    [ -n "$interface" ] || return 2
    interface="/sys/class/net/$interface"
    [ -d "$interface" ] || return 2
    flags=$(cat $interface/flags)
    echo $(($flags|0x41)) > $interface/flags # 0x41: IFF_UP|IFF_RUNNING
    [ "$(cat $interface/carrier)" = 1 ] || return 1
    # XXX Do we need to reset the flags here? anaconda never bothered..
}
