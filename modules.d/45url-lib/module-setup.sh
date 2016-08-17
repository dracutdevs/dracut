#!/bin/bash
# module-setup for url-lib

check() {
    require_binaries curl || return 1
    return 255
}

depends() {
    echo network
    return 0
}

install() {
    local _dir _crt _found _lib
    inst_simple "$moddir/url-lib.sh" "/lib/url-lib.sh"
    inst_multiple curl
    # also install libs for curl https
    inst_libdir_file "libnsspem.so*"
    inst_libdir_file "libnsssysinit.so*"
    inst_libdir_file "libsoftokn3.so*"
    inst_libdir_file "libsqlite3.so*"

    for _dir in $libdirs; do
	[[ -d $_dir ]] || continue
        for _lib in $_dir/libcurl.so.*; do
	    [[ -e $_lib ]] || continue
            _crt=$(grep -F --binary-files=text -z .crt $_lib)
            [[ $_crt ]] || continue
            [[ $_crt == /*/* ]] || continue
            if ! inst "$_crt"; then
                dwarn "Couldn't install '$_crt' SSL CA cert bundle; HTTPS might not work."
                continue
            fi
            _found=1
        done
    done
    [[ $_found ]] || dwarn "Couldn't find SSL CA cert bundle; HTTPS won't work."
}

