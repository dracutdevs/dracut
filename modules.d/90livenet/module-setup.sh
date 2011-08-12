#!/bin/bash
# module-setup.sh for livenet

check() {
    # a live, host-only image doesn't really make a lot of sense
    [[ $hostonly ]] && return 1
    return 0
}

depends() {
    echo network dmsquash-live
    return 0
}

install() {
    dracut_install wget
    mkdir -m 0755 -p "$initdir/etc/ssl/certs"
    if ! inst_simple /etc/ssl/certs/ca-bundle.crt; then
        dwarn "Couldn't find SSL CA cert bundle; HTTPS won't work."
    fi

    inst_hook cmdline 29 "$moddir/parse-livenet.sh"
    inst "$moddir/livenetroot" "/sbin/livenetroot"
}

