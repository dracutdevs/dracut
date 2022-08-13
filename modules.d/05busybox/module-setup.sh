#!/bin/sh

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
    local _busybox _prog _path
    _busybox=$(find_binary busybox)
    inst "$_busybox" /usr/bin/busybox

    for _prog in $("$_busybox" --list); do
        [ "$_prog" = "busybox" ] && continue
        _path=$(find_binary "$_prog")
        [ -z "$_path" ] && continue
        ln_r /usr/bin/busybox "$_path"
    done
}
