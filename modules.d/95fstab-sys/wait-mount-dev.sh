#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh
type det_fs >/dev/null 2>&1 || . /lib/fs-lib.sh

fstab_wait_dev() {
    local _dev _mp _fs _opts _dump _pass _rest
    test -e "$1" || return 1
    while read _dev _mp _fs _opts _dump _pass _rest; do
        [ -z "${_dev%%#*}" ] && continue # Skip comment lines
        case "$_dev" in
        /dev/?*)
            wait_for_dev $_dev;;
        *) ;;
        esac
    done < $1
    return 0
}

[ -f /etc/fstab ] && fstab_wait_dev /etc/fstab
