#!/bin/sh

# replaces all occurrences of 'search' in 'str' with 'replacement'
#
# str_replace str search replacement
#
# example:
# str_replace '  one two  three  ' ' ' '_'
str_replace() {
    local in="$1"
    local s="$2"
    local r="$3"
    local out=''

    while [ "${in##*"$s"*}" != "$in" ]; do
        chop="${in%%"$s"*}"
        out="${out}${chop}$r"
        in="${in#*"$s"}"
    done
    printf -- '%s' "${out}${in}"
}

# get a systemd-compatible unit name from a path
# (mimicks unit_name_from_path_instance())
dev_unit_name() {
    local dev="$1"

    if command -v systemd-escape > /dev/null; then
        systemd-escape -p -- "$dev"
        return $?
    fi

    if [ "$dev" = "/" -o -z "$dev" ]; then
        printf -- "-"
        return 0
    fi

    dev="${1%%/}"
    dev="${dev##/}"
    # shellcheck disable=SC1003
    dev="$(str_replace "$dev" '\' '\x5c')"
    dev="$(str_replace "$dev" '-' '\x2d')"
    if [ "${dev##.}" != "$dev" ]; then
        dev="\x2e${dev##.}"
    fi
    dev="$(str_replace "$dev" '/' '-')"

    printf -- "%s" "$dev"
}

# set_systemd_timeout_for_dev [-n] <dev> [<timeout>]
# Set 'rd.timeout' as the systemd timeout for <dev>
set_systemd_timeout_for_dev() {
    local _name
    local _needreload
    local _noreload
    local _timeout

    [ -z "$DRACUT_SYSTEMD" ] && return 0

    if [ "$1" = "-n" ]; then
        _noreload=1
        shift
    fi

    if [ -n "$2" ]; then
        _timeout="$2"
    else
        _timeout=$(getarg rd.timeout)
    fi

    _timeout=${_timeout:-0}

    _name=$(dev_unit_name "$1")
    if ! [ -L "${PREFIX}/etc/systemd/system/initrd.target.wants/${_name}.device" ]; then
        [ -d "${PREFIX}"/etc/systemd/system/initrd.target.wants ] || mkdir -p "${PREFIX}"/etc/systemd/system/initrd.target.wants
        ln -s ../"${_name}".device "${PREFIX}/etc/systemd/system/initrd.target.wants/${_name}.device"
        type mark_hostonly > /dev/null 2>&1 && mark_hostonly /etc/systemd/system/initrd.target.wants/"${_name}".device
        _needreload=1
    fi

    if ! [ -f "${PREFIX}/etc/systemd/system/${_name}.device.d/timeout.conf" ]; then
        mkdir -p "${PREFIX}/etc/systemd/system/${_name}.device.d"
        {
            echo "[Unit]"
            echo "JobTimeoutSec=$_timeout"
            echo "JobRunningTimeoutSec=$_timeout"
        } > "${PREFIX}/etc/systemd/system/${_name}.device.d/timeout.conf"
        type mark_hostonly > /dev/null 2>&1 && mark_hostonly /etc/systemd/system/"${_name}".device.d/timeout.conf
        _needreload=1
    fi

    if [ -z "$PREFIX" ] && [ "$_needreload" = 1 ] && [ -z "$_noreload" ]; then
        /sbin/initqueue --onetime --unique --name daemon-reload systemctl daemon-reload
    fi
}

# wait_for_dev <dev> [<timeout>]
#
# Installs a initqueue-finished script,
# which will cause the main loop only to exit,
# if the device <dev> is recognized by the system.
wait_for_dev() {
    local _name
    local _noreload

    if [ "$1" = "-n" ]; then
        _noreload=-n
        shift
    fi

    _name="$(str_replace "$1" '/' '\x2f')"

    type mark_hostonly > /dev/null 2>&1 && mark_hostonly "$hookdir/initqueue/finished/devexists-${_name}.sh"

    [ -e "${PREFIX}$hookdir/initqueue/finished/devexists-${_name}.sh" ] && return 0

    printf '[ -e "%s" ]\n' "$1" \
        >> "${PREFIX}$hookdir/initqueue/finished/devexists-${_name}.sh"
    {
        printf '[ -e "%s" ] || ' "$1"
        printf 'warn "\"%s\" does not exist"\n' "$1"
    } >> "${PREFIX}$hookdir/emergency/80-${_name}.sh"

    set_systemd_timeout_for_dev $_noreload "$@"
}

cancel_wait_for_dev() {
    local _name
    _name="$(str_replace "$1" '/' '\x2f')"
    rm -f -- "$hookdir/initqueue/finished/devexists-${_name}.sh"
    rm -f -- "$hookdir/emergency/80-${_name}.sh"
    if [ -n "$DRACUT_SYSTEMD" ]; then
        _name=$(dev_unit_name "$1")
        rm -f -- "${PREFIX}/etc/systemd/system/initrd.target.wants/${_name}.device"
        rm -f -- "${PREFIX}/etc/systemd/system/${_name}.device.d/timeout.conf"
        /sbin/initqueue --onetime --unique --name daemon-reload systemctl daemon-reload
    fi
}
