#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

type info >/dev/null 2>&1 || . /lib/dracut-lib.sh
type fsck_single >/dev/null 2>&1 || . /lib/fs-lib.sh

mount_usr()
{
    local _dev _mp _fs _opts _rest _usr_found _ret
    # check, if we have to mount the /usr filesystem
    while read _dev _mp _fs _opts _rest; do
        if [ "$_mp" = "/usr" ]; then
            echo "$_dev $NEWROOT/$_mp $_fs ${_opts},ro $_rest"
            _usr_found="1"
            break
        fi
    done < "$NEWROOT/etc/fstab" >> /etc/fstab

    if [ "x$_usr_found" != "x" ]; then
        # we have to mount /usr
        fsck_single "$_dev" "$_fs"
        _ret=$?
        echo $_ret >/run/initramfs/usr-fsck
        if [ $_ret -ne 255 ]; then
            info "Mounting /usr"
            mount "$NEWROOT/usr" 2>&1 | vinfo
        fi
    fi
}

mount_usr
