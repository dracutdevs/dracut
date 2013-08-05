#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    return 255
}

depends() {
    return 0
}

install() {
    inst_hook cmdline   00 "$moddir/watchdog.sh"
    inst_hook cmdline   50 "$moddir/watchdog.sh"
    inst_hook pre-trigger 00 "$moddir/watchdog.sh"
    inst_hook initqueue 00 "$moddir/watchdog.sh"
    inst_hook mount     00 "$moddir/watchdog.sh"
    inst_hook mount     50 "$moddir/watchdog.sh"
    inst_hook mount     99 "$moddir/watchdog.sh"
    inst_hook pre-pivot 00 "$moddir/watchdog.sh"
    inst_hook pre-pivot 99 "$moddir/watchdog.sh"
    inst_hook cleanup   00 "$moddir/watchdog.sh"
    inst_hook cleanup   99 "$moddir/watchdog.sh"
    inst_hook emergency 02 "$moddir/watchdog-stop.sh"
    inst_multiple -o wdctl
}

