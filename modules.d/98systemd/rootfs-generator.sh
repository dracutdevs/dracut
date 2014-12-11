#!/bin/sh

type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh

generator_wait_for_dev()
{
    local _name
    local _timeout

    _name="$(str_replace "$1" '/' '\x2f')"
    _timeout=$(getarg rd.timeout)
    _timeout=${_timeout:-0}

    [ -e "$hookdir/initqueue/finished/devexists-${_name}.sh" ] && return 0

    printf '[ -e "%s" ]\n' $1 \
        >> "$hookdir/initqueue/finished/devexists-${_name}.sh"
    {
        printf '[ -e "%s" ] || ' $1
        printf 'warn "\"%s\" does not exist"\n' $1
    } >> "$hookdir/emergency/80-${_name}.sh"

    _name=$(dev_unit_name "$1")
    if ! [ -L /run/systemd/generator/initrd.target.wants/${_name}.device ]; then
        [ -d /run/systemd/generator/initrd.target.wants ] || mkdir -p /run/systemd/generator/initrd.target.wants
        ln -s ../${_name}.device /run/systemd/generator/initrd.target.wants/${_name}.device
    fi

    if ! [ -f /run/systemd/generator/${_name}.device.d/timeout.conf ]; then
        mkdir -p /run/systemd/generator/${_name}.device.d
        {
            echo "[Unit]"
            echo "JobTimeoutSec=$_timeout"
        } > /run/systemd/generator/${_name}.device.d/timeout.conf
    fi
}

generator_mount_rootfs()
{
    local _type=$2
    local _flags=$3
    local _name

    [ -z "$1" ] && return 0

    _name=$(dev_unit_name "$1")
    [ -d /run/systemd/generator ] || mkdir -p /run/systemd/generator
    if ! [ -f /run/systemd/generator/sysroot.mount ]; then
        {
            echo "[Unit]"
            echo "Before=initrd-root-fs.target"
            echo "RequiresOverridable=systemd-fsck@${_name}.service"
            echo "After=systemd-fsck@${_name}.service"
            echo "[Mount]"
            echo "Where=/sysroot"
            echo "What=$1"
            echo "Options=${_flags}"
            echo "Type=${_type}"
        } > /run/systemd/generator/sysroot.mount
    fi
    if ! [ -L /run/systemd/generator/initrd-root-fs.target.requires/sysroot.mount ]; then
        [ -d /run/systemd/generator/initrd-root-fs.target.requires ] || mkdir -p /run/systemd/generator/initrd-root-fs.target.requires
        ln -s ../sysroot.mount /run/systemd/generator/initrd-root-fs.target.requires/sysroot.mount
    fi
}

root=$(getarg root=)
case "$root" in
    block:LABEL=*|LABEL=*)
        root="${root#block:}"
        root="$(echo $root | sed 's,/,\\x2f,g')"
        root="block:/dev/disk/by-label/${root#LABEL=}"
        rootok=1 ;;
    block:UUID=*|UUID=*)
        root="${root#block:}"
        root="block:/dev/disk/by-uuid/${root#UUID=}"
        rootok=1 ;;
    block:PARTUUID=*|PARTUUID=*)
        root="${root#block:}"
        root="block:/dev/disk/by-partuuid/${root#PARTUUID=}"
        rootok=1 ;;
    block:PARTLABEL=*|PARTLABEL=*)
        root="${root#block:}"
        root="block:/dev/disk/by-partlabel/${root#PARTLABEL=}"
        rootok=1 ;;
    /dev/nfs) # ignore legacy /dev/nfs
        ;;
    /dev/*)
        root="block:${root}"
        rootok=1 ;;
esac

if [ "${root%%:*}" = "block" ]; then
   generator_wait_for_dev "${root#block:}" "$RDRETRY"
   grep -q 'root=' /proc/cmdline || generator_mount_rootfs "${root#block:}" "$(getarg rootfstype=)" "$(getarg rootflags=)"
fi

exit 0
