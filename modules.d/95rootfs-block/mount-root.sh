#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh
type det_fs >/dev/null 2>&1 || . /lib/fs-lib.sh

filter_rootopts() {
    rootopts=$1
    # strip ro and rw options
    local OLDIFS="$IFS"
    IFS=,
    set -- $rootopts
    IFS="$OLDIFS"
    local v
    while [ $# -gt 0 ]; do
        case $1 in
            rw|ro);;
            defaults);;
            *)
                v="$v,${1}";;
        esac
        shift
    done
    rootopts=${v#,}
    echo $rootopts
}

mount_root() {
    local _ret
    # sanity - determine/fix fstype
    rootfs=$(det_fs "${root#block:}" "$fstype")
    mount -t ${rootfs} -o "$rflags",ro "${root#block:}" "$NEWROOT"

    READONLY=
    fsckoptions=
    if [ -f "$NEWROOT"/etc/sysconfig/readonly-root ]; then
        . "$NEWROOT"/etc/sysconfig/readonly-root
    fi

    if getargbool 0 "readonlyroot=" -y readonlyroot; then
        READONLY=yes
    fi

    if getarg noreadonlyroot ; then
        READONLY=no
    fi

    if [ -f "$NEWROOT"/fastboot ] || getargbool 0 fastboot ; then
        fastboot=yes
    fi

    if [ -f "$NEWROOT"/fsckoptions ]; then
        fsckoptions=$(cat "$NEWROOT"/fsckoptions)
    fi

    if [ -f "$NEWROOT"/forcefsck ] || getargbool 0 forcefsck ; then
        fsckoptions="-f $fsckoptions"
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
        fsckoptions="$AUTOFSCK_OPT $fsckoptions"
    fi

    rootopts=
    if getargbool 1 rd.fstab -n rd_NO_FSTAB \
        && ! getarg rootflags \
        && [ -f "$NEWROOT/etc/fstab" ] \
        && ! [ -L "$NEWROOT/etc/fstab" ]; then
        # if $NEWROOT/etc/fstab contains special mount options for
        # the root filesystem,
        # remount it with the proper options
        rootopts="defaults"
        while read dev mp fs opts rest; do
            # skip comments
            [ "${dev%%#*}" != "$dev" ] && continue

            if [ "$mp" = "/" ]; then
                # sanity - determine/fix fstype
                rootfs=$(det_fs "${root#block:}" "$fs")
                rootopts=$opts
                break
            fi
        done < "$NEWROOT/etc/fstab"

        rootopts=$(filter_rootopts $rootopts)
    fi

    # we want rootflags (rflags) to take precedence so prepend rootopts to
    # them; rflags is guaranteed to not be empty
    rflags="${rootopts:+"${rootopts},"}${rflags}"

    umount "$NEWROOT"

    # backslashes are treated as escape character in fstab
    # esc_root=$(echo ${root#block:} | sed 's,\\,\\\\,g')
    # printf '%s %s %s %s 1 1 \n' "$esc_root" "$NEWROOT" "$rootfs" "$rflags" >/etc/fstab

    if [ -z "$fastboot" -a "$READONLY" != "yes" ] && ! strstr "${rflags},${rootopts}" _netdev; then
        fsck_single "${root#block:}" "$rootfs" "$fsckoptions"
        _ret=$?
        [ $_ret -ne 255 ] && echo $_ret >/run/initramfs/root-fsck
    fi

    info "Remounting ${root#block:} with -o ${rflags}"
    mount -t "$rootfs" -o "$rflags" "${root#block:}" "$NEWROOT" 2>&1 | vinfo

    [ -f "$NEWROOT"/forcefsck ] && rm -f "$NEWROOT"/forcefsck 2>/dev/null
    [ -f "$NEWROOT"/.autofsck ] && rm -f "$NEWROOT"/.autofsck 2>/dev/null
}

if [ -n "$root" -a -z "${root%%block:*}" ]; then
    mount_root
fi
