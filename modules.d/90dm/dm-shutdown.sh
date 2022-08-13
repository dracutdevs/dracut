#!/bin/sh

_remove_dm() {
    local dev s devname
    dev=$1

    for s in /sys/block/"${dev}"/holders/dm-*; do
        [ -e "${s}" ] || continue
        _remove_dm "${s##*/}"
    done
    # multipath devices might have MD devices on top,
    # which are removed after this script. So do not
    # remove those to avoid spurious errors
    read -r uuid < /sys/block/"${dev}"/dm/uuid
    case "$uuid" in
        mpath-*)
            :
            ;;
        *)
            read -r devname < /sys/block/"${dev}"/dm/name
            dmsetup -v --noudevsync remove "$devname"
            ;;
    esac
}

_do_dm_shutdown() {
    local ret=0
    local final=$1
    local dev

    info "Disassembling device-mapper devices"
    for dev in /sys/block/dm-*; do
        [ -e "${dev}" ] || continue
        if [ -n "$final" ]; then
            _remove_dm "${dev##*/}" || ret=$?
        else
            _remove_dm "${dev##*/}" > /dev/null 2>&1 || ret=$?
        fi
    done
    if [ -n "$final" ]; then
        info "dmsetup ls --tree"
        dmsetup ls --tree 2>&1 | vinfo
    fi
    return $ret
}

if command -v dmsetup > /dev/null \
    && [ "$(dmsetup status)" != "No devices found" ]; then
    _do_dm_shutdown "$1"
fi
