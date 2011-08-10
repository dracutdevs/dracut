#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

# returns OK if $1 contains $2
strstr() {
    [ "${1#*$2*}" != "$1" ]
}

# returns OK if $1 contains $2 at the beginning
str_starts() {
    [ "${1#$2*}" != "$1" ]
}

# replaces all occurrences of 'search' in 'str' with 'replacement'
#
# str_replace str search replacement
#
# example:
# str_replace '  one two  three  ' ' ' '_'
str_replace() {
    local in="$1"; local s="$2"; local r="$3"
    local out=''

    while strstr "${in}" "$s"; do
        chop="${in%%$s*}"
        out="${out}${chop# }$r"
        in="${in#*$s}"
    done
    echo "${out}${in}"
}

_getcmdline() {
    local _line
    unset _line
    if [ -z "$CMDLINE" ]; then
        if [ -e /etc/cmdline ]; then
            while read _line; do
                CMDLINE_ETC="$CMDLINE_ETC $_line";
            done </etc/cmdline;
        fi
        read CMDLINE </proc/cmdline;
        CMDLINE="$CMDLINE $CMDLINE_ETC"
    fi
}

_dogetarg() {
    local _o _val _doecho
    unset _val
    unset _o
    unset _doecho
    _getcmdline

    for _o in $CMDLINE; do
        if [ "${_o%%=*}" = "${1%%=*}" ]; then
            if [ -n "${1#*=}" -a "${1#*=*}" != "${1}" ]; then
                # if $1 has a "=<value>", we want the exact match
                if [ "$_o" = "$1" ]; then
                    _val="1";
                    unset _doecho
                fi
                continue
            fi

            if [ "${_o#*=}" = "$_o" ]; then
                # if cmdline argument has no "=<value>", we assume "=1"
                _val="1";
                unset _doecho
                continue
            fi

            _val=${_o#*=};
            _doecho=1
        fi
    done
    if [ -n "$_val" ]; then
        [ "x$_doecho" != "x" ] && echo "$_val";
        return 0;
    fi
    return 1;
}

getarg() {
    set +x
    while [ $# -gt 0 ]; do
        case $1 in
            -y) if _dogetarg $2 >/dev/null; then
                    echo 1
                    [ "$RD_DEBUG" = "yes" ] && set -x
                    return 0
                fi
                shift 2;;
            -n) if _dogetarg $2 >/dev/null; then
                    echo 0;
                    [ "$RD_DEBUG" = "yes" ] && set -x
                    return 1
                fi
                shift 2;;
            *)  if _dogetarg $1; then
                    [ "$RD_DEBUG" = "yes" ] && set -x
                    return 0;
                fi
                shift;;
        esac
    done
    [ "$RD_DEBUG" = "yes" ] && set -x
    return 1
}

getargbool() {
    local _b
    unset _b
    local _default
    _default=$1; shift
    _b=$(getarg "$@")
    [ $? -ne 0 -a -z "$_b" ] && _b=$_default
    if [ -n "$_b" ]; then
        [ $_b = "0" ] && return 1
        [ $_b = "no" ] && return 1
    fi
    return 0
}

_dogetargs() {
    set +x
    local _o _found _key
    unset _o
    unset _found
    _getcmdline
    _key=$1
    set --
    for _o in $CMDLINE; do
        if [ "$_o" = "$_key" ]; then
            _found=1;
        elif [ "${_o%%=*}" = "${_key%=}" ]; then
            [ -n "${_o%%=*}" ] && set -- "$@" "${_o#*=}";
            _found=1;
        fi
    done
    if [ -n "$_found" ]; then
        [ $# -gt 0 ] && echo -n "$@"
        return 0
    fi
    return 1;
}

getargs() {
    set +x
    local _val _i _args _gfound
    unset _val
    unset _gfound
    _args="$@"
    set --
    for _i in $_args; do
        _val="$(_dogetargs $_i)"
        [ $? -eq 0 ] && _gfound=1
        [ -n "$_val" ] && set -- "$@" "$_val"
    done
    if [ -n "$_gfound" ]; then
        if [ $# -gt 0 ]; then
            echo -n "$@"
        else
            echo -n 1
        fi
        [ "$RD_DEBUG" = "yes" ] && set -x
        return 0
    fi
    [ "$RD_DEBUG" = "yes" ] && set -x
    return 1;
}


# Prints value of given option.  If option is a flag and it's present,
# it just returns 0.  Otherwise 1 is returned.
# $1 = options separated by commas
# $2 = option we are interested in
#
# Example:
# $1 = cipher=aes-cbc-essiv:sha256,hash=sha256,verify
# $2 = hash
# Output:
# sha256
getoptcomma() {
    local line=",$1,"; local opt="$2"; local tmp

    case "${line}" in
        *,${opt}=*,*)
            tmp="${line#*,${opt}=}"
            echo "${tmp%%,*}"
            return 0
            ;;
        *,${opt},*) return 0;;
    esac
    return 1
}

# Splits given string 'str' with separator 'sep' into variables 'var1', 'var2',
# 'varN'.  If number of fields is less than number of variables, remaining are
# not set.  If number of fields is greater than number of variables, the last
# variable takes remaining fields.  In short - it acts similary to 'read'.
#
# splitsep sep str var1 var2 varN
#
# example:
#   splitsep ':' 'foo:bar:baz' v1 v2
# in result:
#   v1='foo', v2='bar:baz'
#
# TODO: ':' inside fields.
splitsep() {
    local sep="$1"; local str="$2"; shift 2
    local tmp

    while [ -n "$str" -a -n "$*" ]; do
        tmp="${str%%$sep*}"
        eval "$1=${tmp}"
        str="${str#$tmp}"
        str="${str#$sep}"
        shift
    done

    return 0
}

setdebug() {
    if [ -z "$RD_DEBUG" ]; then
        if [ -e /proc/cmdline ]; then
            RD_DEBUG=no
            if getargbool 0 rd.debug -y rdinitdebug -y rdnetdebug; then
                RD_DEBUG=yes
                [ -n "$BASH" ] && \
                    export PS4='${BASH_SOURCE}@${LINENO}(${FUNCNAME[0]}): ';
           fi
        fi
        export RD_DEBUG
    fi
    [ "$RD_DEBUG" = "yes" ] && set -x
}

setdebug

source_all() {
    local f
    [ "$1" ] && [  -d "/$1" ] || return
    for f in "/$1"/*.sh; do [ -e "$f" ] && . "$f"; done
}

hookdir=/lib/dracut/hooks
export hookdir

source_hook() {
    source_all "/lib/dracut/hooks/$1"
}

check_finished() {
    local f
    for f in $hookdir/initqueue/finished/*.sh; do { [ -e "$f" ] && ( . "$f" ) ; } || return 1 ; done
    return 0
}

source_conf() {
    local f
    [ "$1" ] && [  -d "/$1" ] || return
    for f in "/$1"/*.conf; do [ -e "$f" ] && . "$f"; done
}

die() {
    {
        echo "<24>dracut: FATAL: $@";
        echo "<24>dracut: Refusing to continue";
    } > /dev/kmsg

    {
        echo "warn dracut: FATAL: \"$@\"";
        echo "warn dracut: Refusing to continue";
    } >> $hookdir/emergency/01-die.sh

    > /run/initramfs/.die
    exit 1
}

check_quiet() {
    if [ -z "$DRACUT_QUIET" ]; then
        DRACUT_QUIET="yes"
        getargbool 0 rd.info -y rdinfo && DRACUT_QUIET="no"
        getargbool 0 rd.debug -y rdinitdebug && DRACUT_QUIET="no"
        getarg quiet || DRACUT_QUIET="yes"
    fi
}

warn() {
    check_quiet
    echo "<28>dracut Warning: $@" > /dev/kmsg
    echo "dracut Warning: $@" >&2
}

info() {
    check_quiet
    echo "<30>dracut: $@" > /dev/kmsg
    [ "$DRACUT_QUIET" != "yes" ] && \
        echo "dracut: $@"
}

vwarn() {
    while read line; do
        warn $line;
    done
}

vinfo() {
    while read line; do
        info $line;
    done
}

check_occurances() {
    # Count the number of times the character $ch occurs in $str
    # Return 0 if the count matches the expected number, 1 otherwise
    local str="$1"
    local ch="$2"
    local expected="$3"
    local count=0

    while [ "${str#*$ch}" != "${str}" ]; do
        str="${str#*$ch}"
        count=$(( $count + 1 ))
    done

    [ $count -eq $expected ]
}

incol2() {
    local dummy check;
    local file="$1";
    local str="$2";

    [ -z "$file" ] && return 1;
    [ -z "$str"  ] && return 1;

    while read dummy check restofline; do
        [ "$check" = "$str" ] && return 0
    done < $file
    return 1
}

udevsettle() {
    [ -z "$UDEVVERSION" ] && UDEVVERSION=$(udevadm --version)

    if [ $UDEVVERSION -ge 143 ]; then
        udevadm settle --exit-if-exists=$hookdir/initqueue/work $settle_exit_if_exists
    else
        udevadm settle --timeout=30
    fi
}

udevproperty() {
    [ -z "$UDEVVERSION" ] && UDEVVERSION=$(udevadm --version)

    if [ $UDEVVERSION -ge 143 ]; then
        for i in "$@"; do udevadm control --property=$i; done
    else
        for i in "$@"; do udevadm control --env=$i; done
    fi
}

ismounted() {
    while read a m a; do
        [ "$m" = "$1" ] && return 0
    done < /proc/mounts
    return 1
}

wait_for_if_up() {
    local cnt=0
    while [ $cnt -lt 20 ]; do
        li=$(ip link show $1)
        [ -z "${li##*state UP*}" ] && return 0
        sleep 0.1
        cnt=$(($cnt+1))
    done
    return 1
}

# root=nfs:[<server-ip>:]<root-dir>[:<nfs-options>]
# root=nfs4:[<server-ip>:]<root-dir>[:<nfs-options>]
nfsroot_to_var() {
    # strip nfs[4]:
    local arg="$@:"
    nfs="${arg%%:*}"
    arg="${arg##$nfs:}"

    # check if we have a server
    if strstr "$arg" ':/*' ; then
        server="${arg%%:/*}"
        arg="/${arg##*:/}"
    fi

    path="${arg%%:*}"

    # rest are options
    options="${arg##$path}"
    # strip leading ":"
    options="${options##:}"
    # strip  ":"
    options="${options%%:}"

    # Does it really start with '/'?
    [ -n "${path%%/*}" ] && path="error";

    #Fix kernel legacy style separating path and options with ','
    if [ "$path" != "${path#*,}" ] ; then
        options=${path#*,}
        path=${path%%,*}
    fi
}

ip_to_var() {
    local v=${1}:
    local i
    set --
    while [ -n "$v" ]; do
        if [ "${v#\[*:*:*\]:}" != "$v" ]; then
            # handle IPv6 address
            i="${v%%\]:*}"
            i="${i##\[}"
            set -- "$@" "$i"
            v=${v#\[$i\]:}
        else
            set -- "$@" "${v%%:*}"
            v=${v#*:}
        fi
    done

    unset ip srv gw mask hostname dev autoconf
    case $# in
        0)  autoconf="error" ;;
        1)  autoconf=$1 ;;
        2)  dev=$1; autoconf=$2 ;;
        *)  ip=$1; srv=$2; gw=$3; mask=$4; hostname=$5; dev=$6; autoconf=$7 ;;
    esac
}

# Create udev rule match for a device with its device name, or the udev property
# ID_FS_UUID or ID_FS_LABEL
#
# example:
#   udevmatch LABEL=boot
# prints:
#   ENV{ID_FS_LABEL}="boot"
#
# TOOD: symlinks
udevmatch() {
    case "$1" in
    UUID=????????-????-????-????-????????????|LABEL=*)
        printf 'ENV{ID_FS_%s}=="%s"' "${1%%=*}" "${1#*=}"
        ;;
    UUID=*)
        printf 'ENV{ID_FS_UUID}=="%s*"' "${1#*=}"
        ;;
    /dev/?*) printf 'KERNEL=="%s"' "${1#/dev/}" ;;
    *) return 255 ;;
    esac
}

# Prints unique path for potential file inside specified directory.  It consists
# of specified directory, prefix and number at the end which is incremented
# until non-existing file is found.
#
# funiq dir prefix
#
# example:
# # ls /mnt
# cdrom0 cdrom1
#
# # funiq /mnt cdrom
# /mnt/cdrom2
funiq() {
    local dir="$1"; local prefix="$2"
    local i=0

    [ -d "${dir}" ] || return 1

    while [ -e "${dir}/${prefix}$i" ]; do
        i=$(($i+1)) || return 1
    done

    echo "${dir}/${prefix}$i"
}

# Creates unique directory and prints its path.  It's using funiq to generate
# path.
#
# mkuniqdir subdir new_dir_name
mkuniqdir() {
    local dir="$1"; local prefix="$2"
    local retdir; local retdir_new

    [ -d "${dir}" ] || mkdir -m 0755 -p "${dir}" || return 1

    retdir=$(funiq "${dir}" "${prefix}") || return 1
    until mkdir -m 0755 "${retdir}" 2>/dev/null; do
        retdir_new=$(funiq "${dir}" "${prefix}") || return 1
        [ "$retdir_new" = "$retdir" ] && return 1
        retdir="$retdir_new"
    done

    echo "${retdir}"
}

# Evaluates command for UUIDs either given as arguments for this function or all
# listed in /dev/disk/by-uuid.  UUIDs doesn't have to be fully specified.  If
# beginning is given it is expanded to all matching UUIDs.  To pass full UUID to
# your command use '$___' as a place holder.  Remember to escape '$'!
#
# foreach_uuid_until [ -p prefix ] command UUIDs
#
# prefix - string to put just before $___
# command - command to be evaluated
# UUIDs - list of UUIDs separated by space
#
# The function returns after *first successful evaluation* of the given command
# with status 0.  If evaluation fails for every UUID function returns with
# status 1.
#
# Example:
# foreach_uuid_until "mount -U \$___ /mnt; echo OK; umount /mnt" \
#       "01234 f512 a235567f-12a3-c123-a1b1-01234567abcb"
foreach_uuid_until() (
    cd /dev/disk/by-uuid

    [ "$1" = -p ] && local prefix="$2" && shift 2
    local cmd="$1"; shift; local uuids_list="$*"
    local uuid; local full_uuid; local ___

    [ -n "${cmd}" ] || return 1

    for uuid in ${uuids_list:-*}; do
        for full_uuid in ${uuid}*; do
            [ -e "${full_uuid}" ] || continue
            ___="${prefix}${full_uuid}"
            eval ${cmd} && return 0
        done
    done

    return 1
)

# Wrap fsck call for device _dev with additional fsck options _fsckopts return
# fsck's return code
wrap_fsck() {
    local _ret _out _dev="$1" _fsckopts="$2"

    info "Checking filesystem."
    info fsck -T $_fsckopts "$_dev"
    _out=$(fsck -T $_fsckopts "$_dev") ; _ret=$?

    # A return of 4 or higher means there were serious problems.
    if [ $_ret -gt 3 ]; then
        echo $_out|vwarn
        warn "fsck returned with error code $_ret"
        warn "*** An error occurred during the file system check."
        warn "*** Dropping you to a shell; the system will try"
        warn "*** to mount the filesystem, when you leave the shell."
        emergency_shell -n "(Repair filesystem)"
    else
        echo $_out|vinfo
        [ $_ret -gt 0 ] && warn "fsck returned with $_ret"
    fi

    return $_ret
}

# Verify supplied filesystem type, fix if it's invalid, warn user if
# appropriate
det_fs() {
    local _dev="$1" _fs="${2:-auto}" _inf="$3" _orig

    _orig="$_fs"
    _fs=$(udevadm info --query=env --name="$_dev" | \
    while read line; do
        if str_starts $line "ID_FS_TYPE="; then
            echo ${line#ID_FS_TYPE=}
            break
        fi
    done)
    _fs=${_fs:-auto}
    if [ "$_fs" = "auto" ]; then
        warn "Cannon detect filesystem type for device $_dev"
    elif [ "$_orig" != "auto" -a "$_fs" != "$_orig" ]; then
        warn "$_inf: detected filesystem '$_fs' instead of '$_orig' for device: $_dev"
    fi
    echo "$_fs"
}
