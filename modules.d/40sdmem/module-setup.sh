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
inst_hook shutdown 40 "$moddir/wipe.sh"
}

installkernel() {
return 0
}

