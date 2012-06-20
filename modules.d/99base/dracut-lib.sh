#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

debug_off() {
    set +x
}

debug_on() {
    [ "$RD_DEBUG" = "yes" ] && set -x
}

# returns OK if $1 contains $2
strstr() {
    [ "${1#*$2*}" != "$1" ]
}

# returns OK if $1 contains $2 at the beginning
str_starts() {
    [ "${1#$2*}" != "$1" ]
}

# returns OK if $1 contains $2 at the end
str_ends() {
    [ "${1%*$2}" != "$1" ]
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
        out="${out}${chop}$r"
        in="${in#*$s}"
    done
    echo "${out}${in}"
}

_getcmdline() {
    local _line
    local _i
    unset _line
    if [ -z "$CMDLINE" ]; then
        unset CMDLINE_ETC CMDLINE_ETC_D
        if [ -e /etc/cmdline ]; then
            while read -r _line; do
                CMDLINE_ETC="$CMDLINE_ETC $_line";
            done </etc/cmdline;
        fi
        for _i in /etc/cmdline.d/*.conf; do
            [ -e "$_i" ] || continue
            while read -r _line; do
                CMDLINE_ETC_D="$CMDLINE_ETC_D $_line";
            done <"$_i";
        done
        read -r CMDLINE </proc/cmdline;
        CMDLINE="$CMDLINE_ETC_D $CMDLINE_ETC $CMDLINE"
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
    debug_off
    while [ $# -gt 0 ]; do
        case $1 in
            -y) if _dogetarg $2 >/dev/null; then
                    echo 1
                    debug_on
                    return 0
                fi
                shift 2;;
            -n) if _dogetarg $2 >/dev/null; then
                    echo 0;
                    debug_on
                    return 1
                fi
                shift 2;;
            *)  if _dogetarg $1; then
                    debug_on
                    return 0;
                fi
                shift;;
        esac
    done
    debug_on
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
        [ $_b = "off" ] && return 1
    fi
    return 0
}

_dogetargs() {
    debug_off
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
    debug_off
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
        debug_on
        return 0
    fi
    debug_on
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
    debug_off
    local sep="$1"; local str="$2"; shift 2
    local tmp

    while [ -n "$str" -a "$#" -gt 1 ]; do
        tmp="${str%%$sep*}"
        eval "$1=${tmp}"
        str="${str#$tmp}"
        str="${str#$sep}"
        shift
    done
    [ -n "$str" -a -n "$1" ] && eval "$1=$str"
    debug_on
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
    debug_on
}

setdebug

source_all() {
    local f
    local _dir
    _dir=$1; shift
    [ "$_dir" ] && [  -d "/$_dir" ] || return
    for f in "/$_dir"/*.sh; do [ -e "$f" ] && . "$f" "$@"; done
}

hookdir=/lib/dracut/hooks
export hookdir

source_hook() {
    local _dir
    _dir=$1; shift
    source_all "/lib/dracut/hooks/$_dir" "$@"
}

check_finished() {
    local f
    for f in $hookdir/initqueue/finished/*.sh; do 
        [ "$f" = "$hookdir/initqueue/finished/*.sh" ] && return 0
        { [ -e "$f" ] && ( . "$f" ) ; } || return 1
    done
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
    emergency_shell
    exit 1
}

check_quiet() {
    if [ -z "$DRACUT_QUIET" ]; then
        DRACUT_QUIET="yes"
        getargbool 0 rd.info -y rdinfo && DRACUT_QUIET="no"
        getargbool 0 rd.debug -y rdinitdebug && DRACUT_QUIET="no"
        getarg quiet || DRACUT_QUIET="yes"
        a=$(getarg loglevel=)
        [ -n "$a" ] && [ $a -ge 28 ] && DRACUT_QUIET="yes"
        export DRACUT_QUIET
    fi
}

if [ ! -x /lib/systemd/systemd ]; then

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

else

    warn() {
        echo "Warning: $@" >&2
    }

    info() {
        echo "$@"
    }

fi

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
    debug_off
    local dummy check;
    local file="$1";
    local str="$2";

    [ -z "$file" ] && return 1;
    [ -z "$str"  ] && return 1;

    while read dummy check restofline; do
        if [ "$check" = "$str" ]; then
            debug_on
            return 0
        fi
    done < $file
    debug_on
    return 1
}

udevsettle() {
    [ -z "$UDEVVERSION" ] && export UDEVVERSION=$(udevadm --version)

    if [ $UDEVVERSION -ge 143 ]; then
        udevadm settle --exit-if-exists=$hookdir/initqueue/work $settle_exit_if_exists
    else
        udevadm settle --timeout=30
    fi
}

udevproperty() {
    [ -z "$UDEVVERSION" ] && export UDEVVERSION=$(udevadm --version)

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
    local li
    while [ $cnt -lt 200 ]; do
        li=$(ip -o link show up dev $1)
        [ -n "$li" ] && return 0
        sleep 0.1
        cnt=$(($cnt+1))
    done
    return 1
}

wait_for_route_ok() {
    local cnt=0
    while [ $cnt -lt 200 ]; do
        li=$(ip route show)
        [ -n "$li" ] && [ -z "${li##*$1*}" ] && return 0
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

# Copy the contents of SRC into DEST, merging the contents of existing
# directories (kinda like rsync, or cpio -p).
# Creates DEST if it doesn't exist. Overwrites files with the same names.
#
# copytree SRC DEST
copytree() {
    local src="$1" dest="$2"
    mkdir -p "$dest"; dest=$(readlink -e -q "$dest")
    ( cd "$src"; cp -af . -t "$dest" )
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

# Get kernel name for given device.  Device may be the name too (then the same
# is returned), a symlink (full path), UUID (prefixed with "UUID=") or label
# (prefixed with "LABEL=").  If just a beginning of the UUID is specified or
# even an empty, function prints all device names which UUIDs match - every in
# single line.
#
# NOTICE: The name starts with "/dev/".
#
# Example:
#   devnames UUID=123
# May print:
#   /dev/dm-1
#   /dev/sdb1
#   /dev/sdf3
devnames() {
    local dev="$1"; local d; local names

    case "$dev" in
    UUID=*)
        dev="$(foreach_uuid_until '! blkid -U $___' "${dev#UUID=}")" \
            && return 255
        [ -z "$dev" ] && return 255
        ;;
    LABEL=*) dev="$(blkid -L "${dev#LABEL=}")" || return 255 ;;
    /dev/?*) ;;
    *) return 255 ;;
    esac

    for d in $dev; do
        names="$names
$(readlink -e -q "$d")" || return 255
    done

    echo "${names#
}"
}


usable_root() {
    local _d
    [ -d $1 ] || return 1
    for _d in proc sys dev; do
        [ -e "$1"/$_d ] || return 1
    done
    return 0
}

inst_hook() {
    local _hookname _unique _name _job _exe
    while [ $# -gt 0 ]; do
        case "$1" in
            --hook)
                _hookname="/$2";shift;;
            --unique)
                _unique="yes";;
            --name)
                _name="$2";shift;;
            *)
                break;;
        esac
        shift
    done

    if [ -z "$_unique" ]; then
        _job="${_name}$$"
    else
        _job="${_name:-$1}"
        _job=${_job##*/}
    fi

    _exe=$1
    shift

    [ -x "$_exe" ] || _exe=$(command -v $_exe)

    if [ -n "$onetime" ]; then
        {
            echo '[ -e "$_job" ] && rm "$_job"'
            echo "$_exe $@"
        } > "/tmp/$$-${_job}.sh"
    else
        echo "$_exe $@" > "/tmp/$$-${_job}.sh"
    fi

    mv -f "/tmp/$$-${_job}.sh" "$hookdir/${_hookname}/${_job}.sh"
}

# inst_mount_hook <mountpoint> <prio> <name> <script>
#
# Install a mount hook with priority <prio>,
# which executes <script> as soon as <mountpoint> is mounted.
inst_mount_hook() {
    local _prio="$2" _jobname="$3" _script="$4"
    local _hookname="mount-$(str_replace "$1" '/' '\\x2f')"
    [ -d "$hookdir/${_hookname}" ] || mkdir -p "$hookdir/${_hookname}"
    inst_hook --hook "$_hookname" --unique --name "${_prio}-${_jobname}" "$_script"
}

# add_mount_point <dev> <mountpoint> <filesystem> <fsopts>
#
# Mount <dev> on <mountpoint> with <filesystem> and <fsopts>
# and call any mount hooks, as soon, as it is mounted
add_mount_point() {
    local _dev="$1" _mp="$2" _fs="$3" _fsopts="$4"
    local _hookname="mount-$(str_replace "$2" '/' '\\x2f')"
    local _devname="dev-$(str_replace "$1" '/' '\\x2f')"
    echo "$_dev $_mp $_fs $_fsopts 0 0" >> /etc/fstab

    exec 7>/etc/udev/rules.d/99-mount-${_devname}.rules
    echo 'SUBSYSTEM!="block", GOTO="mount_end"' >&7
    echo 'ACTION!="add|change", GOTO="mount_end"' >&7
    if [ -n "$_dev" ]; then
        udevmatch "$_dev" >&7 || {
            warn "add_mount_point dev=$_dev incorrect!"
            continue
        }
        printf ', ' >&7
    fi

    {
        printf -- 'RUN+="%s --unique --onetime ' $(command -v initqueue)
        printf -- '--name mount-%%k '
        printf -- '%s %s"\n' "$(command -v mount_hook)" "${_mp}"
    } >&7
    echo 'LABEL="mount_end"' >&7
    exec 7>&-
}

# wait_for_mount <mountpoint>
#
# Installs a initqueue-finished script,
# which will cause the main loop only to exit,
# if <mountpoint> is mounted.
wait_for_mount()
{
    local _name
    _name="$(str_replace "$1" '/' '\\x2f')"
    printf '. /lib/dracut-lib.sh\nismounted "%s"\n' $1 \
        >> "$hookdir/initqueue/finished/ismounted-${_name}.sh"
    {
        printf 'ismounted "%s" || ' $1
        printf 'warn "\"%s\" is not mounted"\n' $1
    } >> "$hookdir/emergency/90-${_name}.sh"
}

# wait_for_dev <dev>
#
# Installs a initqueue-finished script,
# which will cause the main loop only to exit,
# if the device <dev> is recognized by the system.
wait_for_dev()
{
    local _name
    _name="$(str_replace "$1" '/' '\\x2f')"
    printf '[ -e "%s" ]\n' $1 \
        >> "$hookdir/initqueue/finished/devexists-${_name}.sh"
    {
        printf '[ -e "%s" ] || ' $1
        printf 'warn "\"%s\" does not exist"\n' $1
    } >> "$hookdir/emergency/80-${_name}.sh"
}

cancel_wait_for_dev()
{
    local _name
    _name="$(str_replace "$1" '/' '\\x2f')"
    rm -f "$hookdir/initqueue/finished/devexists-${_name}.sh"
    rm -f "$hookdir/emergency/80-${_name}.sh"
}

killproc() {
    debug_off
    local _exe="$(command -v $1)"
    local _sig=$2
    local _i
    [ -x "$_exe" ] || return 1
    for _i in /proc/[0-9]*; do
        [ "$_i" = "/proc/1" ] && continue
        if [ -e "$_i"/_exe ] && [  "$_i/_exe" -ef "$_exe" ] ; then
            kill $_sig ${_i##*/}
        fi
    done
    debug_on
}

need_shutdown() {
    >/run/initramfs/.need_shutdown
}

wait_for_loginit()
{
    [ "$RD_DEBUG" = "yes" ] || return
    [ -e /run/initramfs/loginit.pipe ] || return
    debug_off
    echo "DRACUT_LOG_END"
    exec 0<>/dev/console 1<>/dev/console 2<>/dev/console
        # wait for loginit
    i=0
    while [ $i -lt 10 ]; do
        if [ ! -e /run/initramfs/loginit.pipe ]; then
            j=$(jobs)
            [ -z "$j" ] && break
            [ -z "${j##*Running*}" ] || break
        fi
        sleep 0.1
        i=$(($i+1))
    done

    if [ $i -eq 10 ]; then
        kill %1 >/dev/null 2>&1
        kill $(while read line;do echo $line;done</run/initramfs/loginit.pid)
    fi

    setdebug
    rm -f /run/initramfs/loginit.pipe /run/initramfs/loginit.pid
}

emergency_shell()
{
    local _ctty
    set +e
    local _rdshell_name="dracut" action="Boot" hook="emergency"
    if [ "$1" = "-n" ]; then
        _rdshell_name=$2
        shift 2
    elif [ "$1" = "--shutdown" ]; then
        _rdshell_name=$2; action="Shutdown"; hook="shutdown-emergency"
        shift 2
    fi

    echo ; echo
    warn $@
    source_hook "$hook"
    echo

    if getargbool 1 rd.shell -y rdshell || getarg rd.break rdbreak; then
        if [ -x /lib/systemd/systemd ]; then
            > /.console_lock
            echo "PS1=\"$_rdshell_name:\${PWD}# \"" >/etc/profile
            systemctl start emergency.service
            debug_off
            while [ -e /.console_lock ]; do sleep 1; done
            debug_on
        else
            echo "Dropping to debug shell."
            echo
            export PS1="$_rdshell_name:\${PWD}# "
            [ -e /.profile ] || >/.profile

            _ctty="$(getarg rd.ctty=)" && _ctty="/dev/${_ctty##*/}"
            if [ -z "$_ctty" ]; then
                _ctty=console
                while [ -f /sys/class/tty/$_ctty/active ]; do
                    _ctty=$(cat /sys/class/tty/$_ctty/active)
                    _ctty=${_ctty##* } # last one in the list
                done
                _ctty=/dev/$_ctty
            fi
            [ -c "$_ctty" ] || _ctty=/dev/tty1
            strstr "$(setsid --help 2>/dev/null)" "ctty" && CTTY="-c"
        # stop watchdog
            echo 'V' > /dev/watchdog
            setsid $CTTY /bin/sh -i -l 0<$_ctty 1>$_ctty 2>&1
        fi
    else
        warn "$action has failed. To debug this issue add \"rd.shell\" to the kernel command line."
        # cause a kernel panic
        exit 1
    fi
    [ -e /run/initramfs/.die ] && exit 1
}

# Retain the values of these variables but ensure that they are unexported
# This is a POSIX-compliant equivalent of bash's "export -n"
export_n()
{
    local var
    local val
    for var in "$@"; do
        eval val=\$$var
        unset $var
        [ -n "$val" ] && eval $var=\"$val\"
    done
}
