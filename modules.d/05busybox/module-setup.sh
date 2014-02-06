#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    require_binaries busybox || return 1

    return 255
}

depends() {
    return 0
}

install() {
    local _i _progs _path _busybox
    _busybox=$(type -P busybox)
    inst $_busybox /usr/bin/busybox
    for _i in $($_busybox | sed -ne '1,/Currently/!{s/,//g; s/busybox//g; p}')
    do
        _progs="$_progs $_i"
    done

    # FIXME: switch_root should be in the above list, but busybox version hangs
    # (using busybox-1.15.1-7.fc14.i686 at the time of writing)

    for _i in $_progs; do
        _path=$(find_binary "$_i")
        [ -z "$_path" ] && continue
        ln_r /usr/bin/busybox $_path
    done
}

