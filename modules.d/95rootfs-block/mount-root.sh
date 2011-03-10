#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

. /lib/dracut-lib.sh

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

if [ -n "$root" -a -z "${root%%block:*}" ]; then
    mount -t ${fstype:-auto} -o "$rflags",ro "${root#block:}" "$NEWROOT" \
        && ROOTFS_MOUNTED=yes 

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

    if ! strstr " $fsckoptions" " -y"; then
        fsckoptions="-a $fsckoptions"
    fi

    rootfs=${fstype:-auto}
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
                rootfs=$fs
                rootopts=$opts
                break
            fi
        done < "$NEWROOT/etc/fstab"

        rootopts=$(filter_rootopts $rootopts)
    fi

    umount "$NEWROOT"
    if [ "$rootfs" = "auto" ]; then
        rootfs=$(udevadm info --query=env --name=${root#block:} | \
            while read line; do
                if strstr $line ID_FS_TYPE; then
                    eval $line
                    echo $ID_FS_TYPE
                    break
                fi
            done)
        rootfs=${rootfs:-auto}
    fi

    # backslashes are treated as escape character in fstab
    esc_root=$(echo ${root#block:} | sed 's,\\,\\\\,g')
    printf '%s %s %s %s,%s 1 1 \n' "$esc_root" "$NEWROOT" "$rootfs" "$rflags" "$rootopts"  > /etc/fstab

    if [ -z "$fastboot" -a "$READONLY" != "yes" ]; then
        info "Checking filesystems"
        info fsck -T -t noopts=_netdev -A $fsckoptions
        out=$(fsck -T -t noopts=_netdev -A $fsckoptions) 
        export RD_ROOTFS_FSCK=$?
        echo $RD_ROOTFS_FSCK > /dev/.run/initramfs/root-fsck
        
        # A return of 4 or higher means there were serious problems.
        if [ $RD_ROOTFS_FSCK -gt 3 ]; then
            warn $out
            warn "fsck returned with error code $RD_ROOTFS_FSCK"
            warn "*** An error occurred during the file system check."
            warn "*** Dropping you to a shell; the system will retry"
            warn "*** to mount the system, when you leave the shell."
            emergency_shell -n "(Repair filesystem)"
        else
            echo $out|vinfo
            [ $RD_ROOTFS_FSCK -gt 0 ] && warn "fsck returned with $RD_ROOTFS_FSCK"
        fi
    fi

    info "Remounting ${root#block:} with -o ${rflags},${rootopts}"
    mount -t "$rootfs" -o "$rflags","$rootopts" \
        "${root#block:}" "$NEWROOT" 2>&1 | vinfo

    [ -f "$NEWROOT"/forcefsck ] && rm -f "$NEWROOT"/forcefsck 2>/dev/null
    [ -f "$NEWROOT"/.autofsck ] && rm -f "$NEWROOT"/.autofsck 2>/dev/null
fi
