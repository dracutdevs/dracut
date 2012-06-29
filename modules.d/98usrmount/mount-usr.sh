#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

type info >/dev/null 2>&1 || . /lib/dracut-lib.sh
type fsck_single >/dev/null 2>&1 || . /lib/fs-lib.sh

fsck_usr()
{
    local _dev=$1
    local _fs=$2
    local _fsopts=$3
    local _fsckoptions

    if [ -f "$NEWROOT"/fsckoptions ]; then
        _fsckoptions=$(cat "$NEWROOT"/fsckoptions)
    fi

    if [ -f "$NEWROOT"/forcefsck ] || getargbool 0 forcefsck ; then
        _fsckoptions="-f $_fsckoptions"
    elif [ -f "$NEWROOT"/.autofsck ]; then
        [ -f "$NEWROOT"/etc/sysconfig/autofsck ] && . "$NEWROOT"/etc/sysconfig/autofsck
        if [ "$AUTOFSCK_DEF_CHECK" = "yes" ]; then
            AUTOFSCK_OPT="$AUTOFSCK_OPT -f"
        fi
        if [ -n "$AUTOFSCK_SINGLEUSER" ]; then
            warn "*** Warning -- the system did not shut down cleanly. "
            warn "*** Dropping you to a shell; the system will continue"
            warn "*** when you leave the shell."
            emergency_shell
        fi
        _fsckoptions="$AUTOFSCK_OPT $_fsckoptions"
    fi

    fsck_single "$_dev" "$_fs" "$_fsopts" "$_fsckoptions"
}

mount_usr()
{
    local _dev _mp _fs _opts _rest _usr_found _ret _freq _passno
    # check, if we have to mount the /usr filesystem
    while read _dev _mp _fs _opts _freq _passno; do
        [ "${_dev%%#*}" != "$_dev" ] && continue
        if [ "$_mp" = "/usr" ]; then
            case "$_dev" in
                LABEL=*)
                    _dev="$(echo $_dev | sed 's,/,\\x2f,g')"
                    _dev="/dev/disk/by-label/${_dev#LABEL=}"
		    ;;
                UUID=*)
                    _dev="${_dev#block:}"
                    _dev="/dev/disk/by-uuid/${_dev#UUID=}"
                    ;;
            esac
            echo "$_dev ${NEWROOT}${_mp} $_fs ${_opts} $_freq $_passno"
            _usr_found="1"
            break
        fi
    done < "$NEWROOT/etc/fstab" >> /etc/fstab

    if [ "x$_usr_found" != "x" ]; then
        # we have to mount /usr
        if [ "0" != "${_passno:-0}" ]; then
            fsck_usr "$_dev" "$_fs" "$_opts"
        else
            :
        fi
        _ret=$?
        echo $_ret >/run/initramfs/usr-fsck
        if [ $_ret -ne 255 ]; then
            if getargbool 0 rd.usrmount.ro; then
                info "Mounting /usr (read-only forced)"
                mount -r "$NEWROOT/usr" 2>&1 | vinfo
            else
                info "Mounting /usr"
                mount "$NEWROOT/usr" 2>&1 | vinfo
            fi
        fi
    fi
}

if [ -f "$NEWROOT/etc/fstab" ]; then
    mount_usr
fi
