#!/bin/sh

_do_dm_shutdown() {
    local ret=0
    local final=$1
    info "Disassembling device-mapper devices"
    for dev in $(dmsetup info -c --noheadings -o name) ; do
        dmsetup -v --noudevsync remove "$dev" || ret=$?
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
