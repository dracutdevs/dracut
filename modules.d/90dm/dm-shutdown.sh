#!/bin/sh

_remove_dm() {
    local dev=$1
    local s
    local devname

    for s in /sys/block/${dev}/holders/dm-* ; do
        [ -e ${s} ] || continue
        _remove_dm ${s##*/}
    done
    devname=$(cat /sys/block/${dev}/dm/name)
    dmsetup -v --noudevsync remove "$devname" || return $?
    return 0
}

_do_dm_shutdown() {
    local ret=0
    local final=$1
    local dev

    info "Disassembling device-mapper devices"
    for dev in /sys/block/dm-* ; do
        [ -e ${dev} ] || continue
        _remove_dm ${dev##*/} || ret=$?
    done
    if [ "x$final" != "x" ]; then
        info "dmsetup ls --tree"
        dmsetup ls --tree 2>&1 | vinfo
    fi
    return $ret
}

if command -v dmsetup >/dev/null &&
    [ "x$(dmsetup status)" != "xNo devices found" ]; then
    _do_dm_shutdown $1
else
    :
fi
