#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh
type det_fs >/dev/null 2>&1 || . /lib/fs-lib.sh

fstab_mount() {
    local _dev _mp _fs _opts _dump _pass _rest
    test -e "$1" || return 1
    info "Mounting from $1"
    while read _dev _mp _fs _opts _dump _pass _rest; do
        [ -z "${_dev%%#*}" ] && continue # Skip comment lines
        if [[ ! "$_fs" =~ "nfs" ]] && [ ! -e "$_dev" ]; then
            warn "Device $_dev doesn't exist, skipping mount."
            continue
        fi
        if [ "$_pass" -gt 0 ] && ! strstr "$_opts" _netdev; then
            fsck_single "$_dev" "$_fs"
        fi
        _fs=$(det_fs "$_dev" "$_fs")
        info "Mounting $_dev"
        if [[ -d $NEWROOT/$_mp ]]; then
            mount -v -t $_fs -o $_opts $_dev $NEWROOT/$_mp 2>&1 | vinfo
        else
            mkdir -p "$_mp"
            mount -v -t $_fs -o $_opts $_dev $_mp 2>&1 | vinfo
        fi
    done < $1
    return 0
}

for r in $NEWROOT/etc/fstab.sys /etc/fstab; do
    fstab_mount $r && break
done
