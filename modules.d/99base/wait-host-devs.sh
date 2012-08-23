#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh

wait_host_devs() {
    local _dev

    while read _dev; do
        case "$_dev" in
        /dev/?*)
            wait_for_dev $_dev
            ;;
        *) ;;
        esac
    done < $1
}

[ -f /etc/host_devs ] && wait_host_devs /etc/host_devs
