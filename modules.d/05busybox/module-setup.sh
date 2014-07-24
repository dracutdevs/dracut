#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

# called by dracut
check() {
    require_binaries busybox || return 1

    return 255
}

# called by dracut
depends() {
    return 0
}

# called by dracut
install() {
    local _i _progs _path _busybox
    _busybox=$(type -P busybox)
    inst $_busybox /usr/bin/busybox
    for _i in $($_busybox | sed -ne '1,/Currently/!{s/,//g; s/busybox//g; p}')
    do
        _progs="$_progs $_i"
    done

    for _i in $_progs; do
        _path=$(find_binary "$_i")
        [ -z "$_path" ] && continue
        ln_r /usr/bin/busybox $_path
    done

    # FIXED: switch_root should be in the above list, but busybox version hangs
    inst_hook pre-pivot 30 "$moddir/move_mpoints_to_newroot.sh"
}
