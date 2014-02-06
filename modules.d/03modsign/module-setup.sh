#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
#
# Licensed under the GPLv2
#
# Copyright 2013 Red Hat, Inc.
# Peter Jones <pjones@redhat.com>

check() {
    require_binaries keyctl || return 1

    # do not include module in hostonly mode,
    # if no keys are present
    if [[ $hostonly ]]; then
        x=$(echo /lib/modules/keys/*)
        [[ "${x}" = "/lib/modules/keys/*" ]] && return 255
    fi

    return 0
}

depends() {
    return 0
}

install() {
    inst_dir /lib/modules/keys
    inst_binary /usr/bin/keyctl

    inst_hook pre-trigger 01 "$moddir/load-modsign-keys.sh"

    for x in /lib/modules/keys/* ; do
        [[ "${x}" = "/lib/modules/keys/*" ]] && break
        inst_simple "${x}"
    done
}
