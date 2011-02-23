#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

. /lib/dracut-crypt-lib.sh


real_keydev="$1"; keypath="$2"; luksdev="$3"

[ -z "$real_keydev" -o -z "$keypath" ] && die 'probe-keydev: wrong usage!'
[ -z "$luksdev" ] && luksdev='*'

info "Probing $real_keydev for $keypath..."
test_dev -f "$real_keydev" "$keypath" || exit 1

info "Found $keypath on $real_keydev"
echo "$luksdev:$real_keydev:$keypath" >> /tmp/luks.keys
