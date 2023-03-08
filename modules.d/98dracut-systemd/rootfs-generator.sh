#!/bin/sh

type getarg > /dev/null 2>&1 || . /lib/dracut-lib.sh

generator_wait_for_dev() {
    local _name
    local _timeout

    _name=$(dev_unit_name "$1")
    _timeout=$(getarg rd.timeout)
    _timeout=${_timeout:-0}

    if ! [ -L "$GENERATOR_DIR"/initrd.target.wants/"${_name}".device ]; then
        [ -d "$GENERATOR_DIR"/initrd.target.wants ] || mkdir -p "$GENERATOR_DIR"/initrd.target.wants
        ln -s ../"${_name}".device "$GENERATOR_DIR"/initrd.target.wants/"${_name}".device
    fi

    if ! [ -f "$GENERATOR_DIR"/"${_name}".device.d/timeout.conf ]; then
        mkdir -p "$GENERATOR_DIR"/"${_name}".device.d
        {
            echo "[Unit]"
            echo "JobTimeoutSec=$_timeout"
            echo "JobRunningTimeoutSec=$_timeout"
        } > "$GENERATOR_DIR"/"${_name}".device.d/timeout.conf
    fi
}

generator_mount_rootfs() {
    local _type="$2"
    local _flags="$3"
    local _name

    [ -z "$1" ] && return 0

    _name=$(dev_unit_name "$1")
    if ! [ -f "$GENERATOR_DIR"/sysroot.mount ]; then
        {
            echo "[Unit]"
            echo "Before=initrd-root-fs.target"
            echo "Requires=systemd-fsck@${_name}.service"
            echo "After=systemd-fsck@${_name}.service"
            echo "[Mount]"
            echo "Where=/sysroot"
            echo "What=$1"
            echo "Options=${_flags}"
            echo "Type=${_type}"
        } > "$GENERATOR_DIR"/sysroot.mount
    fi
    if ! [ -L "$GENERATOR_DIR"/initrd-root-fs.target.requires/sysroot.mount ]; then
        [ -d "$GENERATOR_DIR"/initrd-root-fs.target.requires ] || mkdir -p "$GENERATOR_DIR"/initrd-root-fs.target.requires
        ln -s ../sysroot.mount "$GENERATOR_DIR"/initrd-root-fs.target.requires/sysroot.mount
    fi
}

generator_fsck_after_pre_mount() {
    local _name

    [ -z "$1" ] && return 0

    _name=$(dev_unit_name "$1")
    [ -d "$GENERATOR_DIR"/systemd-fsck@"${_name}".service.d ] || mkdir -p "$GENERATOR_DIR"/systemd-fsck@"${_name}".service.d
    if ! [ -f "$GENERATOR_DIR"/systemd-fsck@"${_name}".service.d/after-pre-mount.conf ]; then
        {
            echo "[Unit]"
            echo "After=dracut-pre-mount.service"
        } > "$GENERATOR_DIR"/systemd-fsck@"${_name}".service.d/after-pre-mount.conf
    fi

}

root=$(getarg root=)
case "${root#block:}" in
    LABEL=* | UUID=* | PARTUUID=* | PARTLABEL=*)
        root="block:$(label_uuid_to_dev "$root")"
        rootok=1
        ;;
    /dev/nfs) # ignore legacy /dev/nfs
        ;;
    /dev/*)
        root="block:${root}"
        rootok=1
        ;;
esac

if [ "$rootok" = "1" ]; then
    GENERATOR_DIR="$1"
    [ -z "$GENERATOR_DIR" ] && exit 1
    [ -d "$GENERATOR_DIR" ] || mkdir -p "$GENERATOR_DIR"

    generator_wait_for_dev "${root#block:}"
    generator_fsck_after_pre_mount "${root#block:}"
    strstr "$(cat /proc/cmdline)" 'root=' || generator_mount_rootfs "${root#block:}" "$(getarg rootfstype=)" "$(getarg rootflags=)"
fi

exit 0
