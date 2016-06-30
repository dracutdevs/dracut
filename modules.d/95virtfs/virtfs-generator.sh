#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh

[ -z "$root" ] && root=$(getarg root=)

[ "${root%%:*}" = "virtfs" ] || exit 0

GENERATOR_DIR="$2"
[ -z "$GENERATOR_DIR" ] && exit 1

[ -d "$GENERATOR_DIR" ] || mkdir "$GENERATOR_DIR"

ROOTFLAGS=$(getarg rootflags=) || ROOTFLAGS="trans=virtio,version=9p2000.L"
ROOTFSTYPE=$(getarg rootfstype=) || ROOTFSTYPE="9p"

root=${root#virtfs:}

if getarg "ro"; then
    if [ -n "$ROOTFLAGS" ]; then
        ROOTFLAGS="$ROOTFLAGS,ro"
    else
        ROOTFLAGS="ro"
    fi
fi

{
    echo "[Unit]"
    echo "Before=initrd-root-fs.target"
    echo "[Mount]"
    echo "Where=/sysroot"
    echo "What=${root}"
    [ -n "$ROOTFSTYPE" ] && echo "Type=${ROOTFSTYPE}"
    [ -n "$ROOTFLAGS" ] && echo "Options=${ROOTFLAGS}"
} > "$GENERATOR_DIR"/sysroot.mount

exit 0
