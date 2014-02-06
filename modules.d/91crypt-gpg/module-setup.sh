#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

# GPG support is optional
# called by dracut
check() {
    require_binaries gpg || return 1

    return 255
}

# called by dracut
depends() {
    echo crypt
}

# called by dracut
install() {
    inst_multiple gpg
    inst "$moddir/crypt-gpg-lib.sh" "/lib/dracut-crypt-gpg-lib.sh"
}
