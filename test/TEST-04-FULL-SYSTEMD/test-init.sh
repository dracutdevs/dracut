#!/bin/sh
# shellcheck disable=SC2015

: > /dev/watchdog
getcmdline() {
    while read -r _line || [ -n "$_line" ]; do
        printf "%s" "$_line"
    done < /proc/cmdline
}

_dogetarg() {
    local _o _val _doecho
    unset _val
    unset _o
    unset _doecho
    CMDLINE=$(getcmdline)

    for _o in $CMDLINE; do
        if [ "${_o%%=*}" = "${1%%=*}" ]; then
            if [ -n "${1#*=}" -a "${1#*=*}" != "${1}" ]; then
                # if $1 has a "=<value>", we want the exact match
                if [ "$_o" = "$1" ]; then
                    _val="1"
                    unset _doecho
                fi
                continue
            fi

            if [ "${_o#*=}" = "$_o" ]; then
                # if cmdline argument has no "=<value>", we assume "=1"
                _val="1"
                unset _doecho
                continue
            fi

            _val="${_o#*=}"
            _doecho=1
        fi
    done
    if [ -n "$_val" ]; then
        [ "x$_doecho" != "x" ] && echo "$_val"
        return 0
    fi
    return 1
}

getarg() {
    local _deprecated _newoption
    while [ $# -gt 0 ]; do
        case $1 in
            -d)
                _deprecated=1
                shift
                ;;
            -y)
                if _dogetarg "$2" > /dev/null; then
                    if [ "$_deprecated" = "1" ]; then
                        [ -n "$_newoption" ] && warn "Kernel command line option '$2' is deprecated, use '$_newoption' instead." || warn "Option '$2' is deprecated."
                    fi
                    echo 1
                    return 0
                fi
                _deprecated=0
                shift 2
                ;;
            -n)
                if _dogetarg "$2" > /dev/null; then
                    echo 0
                    if [ "$_deprecated" = "1" ]; then
                        [ -n "$_newoption" ] && warn "Kernel command line option '$2' is deprecated, use '$_newoption=0' instead." || warn "Option '$2' is deprecated."
                    fi
                    return 1
                fi
                _deprecated=0
                shift 2
                ;;
            *)
                if [ -z "$_newoption" ]; then
                    _newoption="$1"
                fi
                if _dogetarg "$1"; then
                    if [ "$_deprecated" = "1" ]; then
                        [ -n "$_newoption" ] && warn "Kernel command line option '$1' is deprecated, use '$_newoption' instead." || warn "Option '$1' is deprecated."
                    fi
                    return 0
                fi
                _deprecated=0
                shift
                ;;
        esac
    done
    return 1
}

getargbool() {
    local _b
    unset _b
    local _default
    _default="$1"
    shift
    _b=$(getarg "$@") || _b="$_default"
    if [ -n "$_b" ]; then
        [ "$_b" = "0" ] && return 1
        [ "$_b" = "no" ] && return 1
        [ "$_b" = "off" ] && return 1
    fi
    return 0
}
export PATH=/sbin:/bin:/usr/sbin:/usr/bin
strstr() { [ "${1##*"$2"*}" != "$1" ]; }
CMDLINE=$(while read -r line || [ -n "$line" ]; do echo "$line"; done < /proc/cmdline)
plymouth --quit
exec < /dev/console > /dev/console 2>&1

ismounted() {
    while read -r _ m _ || [ -n "$m" ]; do
        [ "$m" = "$1" ] && return 0
    done < /proc/mounts
    return 1
}

systemctl --failed --no-legend --no-pager > /failed

if ! ismounted /usr; then
    echo "**************************FAILED**************************"
    echo "/usr not mounted!!"
    cat /proc/mounts
    echo "**************************FAILED**************************"
else
    if [ -s /failed ]; then
        echo "**************************FAILED**************************"
        cat /failed
        echo "**************************FAILED**************************"

    else
        echo "dracut-root-block-success" | dd oflag=direct,dsync of=/dev/sdc
        echo "All OK"
    fi
fi

export TERM=linux
export PS1='initramfs-test:\w\$ '
[ -f /etc/mtab ] || ln -sfn /proc/mounts /etc/mtab
[ -f /etc/fstab ] || ln -sfn /proc/mounts /etc/fstab
stty sane
echo "made it to the rootfs!"
if getargbool 0 rd.shell; then
    #	while sleep 1; do sleep 1;done
    strstr "$(setsid --help)" "control" && CTTY="-c"
    setsid $CTTY sh -i
fi
set -x
/usr/bin/systemctl poweroff
echo "Powering down."
