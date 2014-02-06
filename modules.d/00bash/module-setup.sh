#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    require_binaries /bin/bash
}

depends() {
    return 0
}

install() {
    # If another shell is already installed, do not use bash
    [[ -x $initdir/bin/sh ]] && return

    # Prefer bash as /bin/sh if it is available.
    inst /bin/bash && ln -sf bash "${initdir}/bin/sh"
}

