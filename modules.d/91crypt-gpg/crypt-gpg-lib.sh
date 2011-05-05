#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=4 sw=4 sts=0 et filetype=sh

command -v ask_for_password >/dev/null || . /lib/dracut-crypt-lib.sh

# gpg_decrypt mnt_point keypath keydev device
#
# Decrypts encrypted symmetrically key to standard output.
#
# mnt_point - mount point where <keydev> is already mounted
# keypath - GPG encrypted key path relative to <mnt_point>
# keydev - device on which key resides; only to display in prompt
# device - device to be opened by cryptsetup; only to display in prompt
gpg_decrypt() {
    local mntp="$1"
    local keypath="$2"
    local keydev="$3"
    local device="$4"

    local gpghome=/tmp/gnupg
    local opts="--homedir $gpghome --no-mdc-warning --skip-verify --quiet"
    opts="$opts --logger-file /dev/null --batch --no-tty --passphrase-fd 0"

    mkdir -m 0700 -p "$gpghome"

    ask_for_password \
        --cmd "gpg $opts --decrypt $mntp/$keypath" \
        --prompt "Password ($keypath on $keydev for $device)" \
        --tries 3 --tty-echo-off

    rm -rf -- "$gpghome"
}
