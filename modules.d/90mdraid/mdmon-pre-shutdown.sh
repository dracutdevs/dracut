#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
_do_mdmon_takeover() {
    local ret
    mdmon --takeover --all
    ret=$?
    [ $ret -eq 0 ] && info "Taking over mdmon processes."
    return $ret
}

if command -v mdmon >/dev/null; then
    _do_mdmon_takeover $1
fi
