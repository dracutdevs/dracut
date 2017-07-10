#!/bin/bash

# called by dracut
check() {
    return 255
}

# called by dracut
depends() {
    echo multipath
    return 0
}

# called by dracut
install() {
    local _f _allow

    is_mpath() {
        local _dev=$1
        [ -e /sys/dev/block/$_dev/dm/uuid ] || return 1
        [[ $(cat /sys/dev/block/$_dev/dm/uuid) =~ mpath- ]] && return 0
        return 1
    }

    majmin_to_mpath_dev() {
        local _dev
        for i in /dev/mapper/*; do
            [[ $i == /dev/mapper/control ]] && continue
            _dev=$(get_maj_min $i)
            if [ "$_dev" = "$1" ]; then
                echo $i
                return
            fi
        done
    }

    add_hostonly_mpath_conf() {
        is_mpath $1 && {
            local _dev

            _dev=$(majmin_to_mpath_dev $1)
            [ -z "$_dev" ] && return
            strstr "$_allow" "$_dev" && return
            _allow="$_allow --allow $_dev"
        }
    }

    [[ $hostonly ]] && {
        for_each_host_dev_and_slaves_all add_hostonly_mpath_conf
        [ -n "$_allow" ] && mpathconf $_allow --outfile ${initdir}/etc/multipath.conf
    }
}

