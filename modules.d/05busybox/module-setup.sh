#!/bin/bash

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
    local NOT_FROM_BUSYBOX="${NOT_FROM_BUSYBOX} busybox losetup switch_root sh ,"
    NOT_FROM_BUSYBOX="$(for _i in ${NOT_FROM_BUSYBOX}; do _i=${_i##*/}; [[ -n "$_i" ]] && echo -n " s/$_i//g;"; done)"
    _busybox=$(type -P busybox)
    inst $_busybox /usr/bin/busybox
    for _i in $($_busybox | sed -ne '1,/Currently/!{'"${NOT_FROM_BUSYBOX}"' p}')
    do
        _progs="$_progs $_i"
    done

    for _i in $_progs; do
        _path=$(find_binary "$_i")
        [ -z "$_path" ] && continue
        ln_r /usr/bin/busybox $_path
    done
}
