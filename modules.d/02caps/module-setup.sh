#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    type -P capsh >/dev/null 2>&1
}

depends() {
    return 0
}

install() {
    inst_hook pre-pivot 00 "$moddir/caps.sh"
    inst $(type -P capsh 2>/dev/null) /usr/sbin/capsh
    # capsh wants bash and we need bash also
    inst /bin/bash && ln -sf bash "${initdir}/bin/sh"
}

