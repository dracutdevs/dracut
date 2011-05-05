#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

# GPG support is optional
check() {
    type -P gpg >/dev/null || return 1

    return 255
}

depends() {
    echo crypt
}

install() {
    dracut_install gpg
    inst "$moddir/crypt-gpg-lib.sh" "/lib/dracut-crypt-gpg-lib.sh"
}
