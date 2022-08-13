#!/bin/sh
#
# Licensed under the GPLv2
#
# Copyright 2013 Red Hat, Inc.
# Peter Jones <pjones@redhat.com>

# called by dracut
check() {
    require_binaries keyctl || return 1

    # do not include module in hostonly mode,
    # if no keys are present
    [ -n "$hostonly" ] && [ "$(echo "$dracutsysrootdir"/lib/modules/keys/*)" = "$dracutsysrootdir/lib/modules/keys/*" ] && return 255

    return 0
}

# called by dracut
depends() {
    return 0
}

# called by dracut
install() {
    inst_dir /lib/modules/keys
    inst_binary keyctl

    inst_hook pre-trigger 01 "$moddir/load-modsign-keys.sh"

    for x in "$dracutsysrootdir"/lib/modules/keys/*; do
        [ "${x}" = "$dracutsysrootdir/lib/modules/keys/*" ] && break
        inst_simple "${x#"$dracutsysrootdir"}"
    done
}
