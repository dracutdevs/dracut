#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh

fsck_ask_reboot() {
    info "note - fsck suggests reboot, if you"
    info "leave shell, booting will continue normally"
    emergency_shell -n "(reboot ?)"
}

fsck_ask_err() {
    warn "*** An error occurred during the file system check."
    warn "*** Dropping you to a shell; the system will try"
    warn "*** to mount the filesystem(s), when you leave the shell."
    emergency_shell -n "(Repair filesystem)"
}

# inherits: _ret _drv _out
fsck_tail() {
    [ $_ret -gt 0 ] && warn "$_drv returned with $_ret"
    if [ $_ret -ge 4 ]; then
        [ -n "$_out" ] && echo "$_out"|vwarn
        fsck_ask_err
    else
        [ -n "$_out" ] && echo "$_out"|vinfo
        [ $_ret -ge 2 ] && fsck_ask_reboot
    fi
}

# note: this function sets _drv of the caller
fsck_able() {
    case "$1" in
        xfs)
            # {
            #     type xfs_db &&
            #     type xfs_repair &&
            #     type xfs_check &&
            #     type mount &&
            #     type umount
            # } >/dev/null 2>&1 &&
            # _drv="_drv=none fsck_drv_xfs" &&
            # return 0
            return 1
            ;;
        ext?)
            type e2fsck >/dev/null 2>&1 &&
            _drv="_drv=e2fsck fsck_drv_com" &&
            return 0
            ;;
        jfs)
            type jfs_fsck >/dev/null 2>&1 &&
            _drv="_drv=jfs_fsck fsck_drv_com" &&
            return 0
            ;;
        reiserfs)
            type reiserfsck >/dev/null 2>&1 &&
            _drv="_drv=reiserfsck fsck_drv_com" &&
            return 0
            ;;
        btrfs)
            # type btrfsck >/dev/null 2>&1 &&
            # _drv="_drv=none fsck_drv_btrfs" &&
            # return 0
            return 1
            ;;
        nfs*)
            # nfs can be a nop, returning success
            _drv="_drv=none :" &&
            return 0
            ;;
        *)
            type fsck >/dev/null 2>&1 &&
            _drv="_drv=fsck fsck_drv_std" &&
            return 0
            ;;
    esac

    return 1
}

# note: all drivers inherit: _drv _fop _dev

fsck_drv_xfs() {
    # xfs fsck is not necessary... Either it mounts or not
    return 0
}

fsck_drv_btrfs() {
    # btrfs fsck is not necessary... Either it mounts or not
    return 0
}

# common code for checkers that follow usual subset of options and return codes
fsck_drv_com() {
    local _ret
    local _out

    if ! strstr "$_fop" "-[ynap]"; then
        _fop="-a ${_fop}"
    fi

    info "issuing $_drv $_fop $_dev"
    # we enforce non-interactive run, so $() is fine
    _out=$($_drv $_fop "$_dev")
    _ret=$?
    fsck_tail

    return $_ret
}

# code for generic fsck, if the filesystem checked is "unknown" to us
fsck_drv_std() {
    local _ret
    local _out
    unset _out

    info "issuing fsck $_fop $_dev"
    # note, we don't enforce -a here, thus fsck is being run (in theory)
    # interactively; otherwise some tool might complain about lack of terminal
    # (and using -a might not be safe)
    fsck $_fop "$_dev" >/dev/console 2>&1
    _ret=$?
    fsck_tail

    return $_ret
}

# checks single filesystem, relying on specific "driver"; we don't rely on
# automatic checking based on fstab, so empty one is passed;
# takes 4 arguments - device, filesystem, filesystem options, additional fsck options;
# first 2 arguments are mandatory (fs may be auto or "")
# returns 255 if filesystem wasn't checked at all (e.g. due to lack of
# necessary tools or insufficient options)
fsck_single() {
    local FSTAB_FILE=/etc/fstab.empty
    local _dev="$1"
    local _fs="${2:-auto}"
    local _fsopts="$3"
    local _fop="$4"
    local _drv

    [ $# -lt 2 ] && return 255
    # if UUID= marks more than one device, take only the first one
    [ -e "$_dev" ] || _dev=$(devnames "$_dev"| while read line; do if [ -n "$line" ]; then echo $line; break;fi;done)
    [ -e "$_dev" ] || return 255
    _fs=$(det_fs "$_dev" "$_fs")
    fsck_able "$_fs" || return 255

    info "Checking $_fs: $_dev"
    export FSTAB_FILE
    eval "$_drv"
    return $?
}

# takes list of filesystems to check in parallel; we don't rely on automatic
# checking based on fstab, so empty one is passed
fsck_batch() {
    local FSTAB_FILE=/etc/fstab.empty
    local _drv=fsck
    local _dev
    local _ret
    local _out

    [ $# -eq 0 ] || ! type fsck >/dev/null 2>&1 && return 255

    info "Checking filesystems (fsck -M -T -a):"
    for _dev in "$@"; do
        info "    $_dev"
    done

    export FSTAB_FILE
    _out="$(fsck -M -T "$@" -- -a)"
    _ret=$?

    fsck_tail

    return $_ret
}

# verify supplied filesystem type:
# if user provided the fs and we couldn't find it, assume user is right
# if we found the fs, assume we're right
det_fs() {
    local _dev="$1"
    local _orig="${2:-auto}"
    local _fs

    _fs=$(udevadm info --query=env --name="$_dev" | \
    while read line; do
        if str_starts $line "ID_FS_TYPE="; then
            echo ${line#ID_FS_TYPE=}
            break
        fi
    done)
    _fs=${_fs:-auto}

    if [ "$_fs" = "auto" ]; then
        _fs="$_orig"
    fi
    echo "$_fs"
}

write_fs_tab() {
    local _o
    local _rw
    local _root
    local _rootfstype
    local _rootflags
    local _fspassno

    _fspassno="0"
    _root="$1"
    _rootfstype="$2"
    _rootflags="$3"
    [ -z "$_rootfstype" ] && _rootfstype=$(getarg rootfstype=)
    [ -z "$_rootflags" ] && _rootflags=$(getarg rootflags=)

    [ -z "$_rootfstype" ] && _rootfstype="auto"

    if [ -z "$_rootflags" ]; then
        _rootflags="ro,x-initrd.mount"
    else
        _rootflags="ro,$_rootflags,x-initrd.mount"
    fi

    _rw=0
    for _o in $CMDLINE; do
        case $_o in
            rw)
                _rw=1;;
            ro)
                _rw=0;;
        esac
    done
    if [ "$_rw" = "1" ]; then
        _rootflags="$_rootflags,rw"
        if ! getargbool 0 rd.skipfsck; then
            _fspassno="1"
        fi
    fi

    echo "$_root /sysroot $_rootfstype $_rootflags $_fspassno 0" >> /etc/fstab

    if type systemctl >/dev/null 2>/dev/null; then
        systemctl daemon-reload
        systemctl --no-block start initrd-root-fs.target
    fi
}

# fstab_mount FSTAB
# go through FSTAB and mount each line
# cannot be used to mount rootfs for 40network, because it will not create /dev/root
fstab_mount() {
    local _dev _mp _fs _opts _dump _pass _rest
    test -e "$1" || return 1
    info "Mounting from $1"
    while read _dev _mp _fs _opts _dump _pass _rest; do
        [ -z "${_dev%%#*}" ] && continue # Skip comment lines
        ismounted $_mp && continue # Skip mounted filesystem
        if [ "$_pass" -gt 0 ] && ! strstr "$_opts" _netdev; then
            fsck_single "$_dev" "$_fs" "$_opts"
        fi
        _fs=$(det_fs "$_dev" "$_fs")
        info "Mounting $_dev"
        if [ -d "$NEWROOT/$_mp" ]; then
            mount -v -t $_fs -o $_opts $_dev "$NEWROOT/$_mp" 2>&1 | vinfo
        else
            [ -d "$_mp" ] || mkdir -p "$_mp"
            mount -v -t $_fs -o $_opts $_dev $_mp 2>&1 | vinfo
        fi
    done < $1
    return 0
}

# fs_add_mount PHASE FS MOUNTPOINT FSTYPE OPTIONS DUMP PASS
# add line to fstab used by pre-mount (PHASE=early) or pre-pivot (PHASE=late) hook
# FS is anything that could be found in the first column of fstab
fs_add_mount() {
	local phase="$1" fs="$2" mountpoint="$3" fstype="$4" options="$5" dump="$6" pass="$7"
	[ "${fs}" ] || die "FS passed to $0 is empty"
	[ "${mountpoint}" ] || die "Mountpoint passed to $0 is empty"
	[ "${fstype}" ] || fstype=auto
	[ "${options}" ] || options=defaults
	[ "${dump}" ] || dump=0
	[ "${pass}" ] || pass=0
	echo "${fs} ${mountpoint} ${fstype} ${options} ${dump} ${pass}" >> /etc/fstab."${phase}"
}

# fs_mount_to_var MOUNTSPEC
# use MOUNTSPEC to set $mountpoint, $fstype, $fs and $options.
# MOUNTSPEC is something like: [<mountpoint>]:<fstype>:<fs>[,<options>]
fs_mount_to_var() {
	local arg="$1"

	options="${arg#*,}"
	[ "${options}" = "${arg}" ] && unset options
	arg="${arg%%,${options}}"

	mountpoint="${arg%%:*}"
	[ "${mountpoint}" = "${arg}" ] && die "Unable to parse mountpoint out of $1"
	arg="${arg##${mountpoint}:}"

	if [ "${mountpoint}" = "${mountpoint#/}" ] ; then
		fstype="${mountpoint}"
		mountpoint=/
	else
		fstype="${arg%%:*}"
		[ "${fstype}" = "${arg}" ] && die "Unable to parse fstype out of $1"
		arg="${arg##${fstype}:}"
	fi

	fs="${arg}"
}
