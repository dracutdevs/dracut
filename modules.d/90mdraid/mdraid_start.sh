#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh
_md_force_run() {
    local _udevinfo
    local _path_s
    local _path_d
    local _offroot
    _offroot=$(strstr "$(mdadm --help-options 2>&1)" offroot && echo --offroot)
    # try to force-run anything not running yet
    for md in /dev/md[0-9_]*; do
        [ -b "$md" ] || continue
        _udevinfo="$(udevadm info --query=env --name="$md")"
        strstr "$_udevinfo" "MD_LEVEL=container" && continue
        strstr "$_udevinfo" "DEVTYPE=partition" && continue

        _path_s="/sys/$(udevadm info -q path -n "$md")/md/array_state"
        [ ! -r "$_path_s" ] && continue

        # inactive ?
        [ "$(cat "$_path_s")" != "inactive" ] && continue

        mdadm $_offroot -R "$md" 2>&1 | vinfo

        # still inactive ?
        [ "$(cat "$_path_s")" = "inactive" ] && continue

        _path_d="${_path_s%/*}/degraded"
        [ ! -r "$_path_d" ] && continue
    done
}

_md_force_run
