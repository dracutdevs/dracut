#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    return 0
}

depends() {
    return 0
}

install() {
    inst_hook cmdline 20 "$moddir/parse-insmodpost.sh"
    inst_simple "$moddir/insmodpost.sh" /sbin/insmodpost.sh
}

