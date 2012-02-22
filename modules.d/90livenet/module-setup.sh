#!/bin/bash
# module-setup.sh for livenet

check() {
    return 255
}

depends() {
    echo network url-lib dmsquash-live
    return 0
}

install() {
    inst_hook cmdline 29 "$moddir/parse-livenet.sh"
    inst "$moddir/livenetroot.sh" "/sbin/livenetroot"
}

