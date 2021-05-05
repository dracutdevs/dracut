#!/bin/bash

type getarg > /dev/null 2>&1 || . /lib/dracut-lib.sh

[ -z "$root" ] && root=$(getarg root=)

# support legacy syntax of passing liveimg and then just the base root
if getargbool 0 rd.live.image -d -y liveimg; then
    liveroot="live:$root"
fi

if [ "${root%%:*}" = "live" ]; then
    liveroot=$root
fi

[ "${liveroot%%:*}" = "live" ] || exit 0

case "$liveroot" in
    live:nfs://* | nfs://*)
        root="${root#live:}"
        rootok=1
        ;;
    live:http://* | http://*)
        root="${root#live:}"
        rootok=1
        ;;
    live:https://* | https://*)
        root="${root#live:}"
        rootok=1
        ;;
    live:ftp://* | ftp://*)
        root="${root#live:}"
        rootok=1
        ;;
    live:torrent://* | torrent://*)
        root="${root#live:}"
        rootok=1
        ;;
    live:tftp://* | tftp://*)
        root="${root#live:}"
        rootok=1
        ;;
esac

[ "$rootok" != "1" ] && exit 0

GENERATOR_DIR="$2"
[ -z "$GENERATOR_DIR" ] && exit 1

[ -d "$GENERATOR_DIR" ] || mkdir -p "$GENERATOR_DIR"

getargbool 0 rd.live.overlay.readonly -d -y readonly_overlay && readonly_overlay="--readonly" || readonly_overlay=""
getargbool 0 rd.live.overlay.overlayfs && overlayfs="yes"
[ -e /xor_overlayfs ] && xor_overlayfs="yes"
[ -e /xor_readonly ] && xor_readonly="--readonly"
ROOTFLAGS="$(getarg rootflags)"
{
    echo "[Unit]"
    echo "Before=initrd-root-fs.target"
    echo "[Mount]"
    echo "Where=/sysroot"
    if [ "$overlayfs$xor_overlayfs" = "yes" ]; then
        echo "What=LiveOS_rootfs"
        if [ "$readonly_overlay$xor_readonly" = "--readonly" ]; then
            ovlfs=lowerdir=/run/overlayfs-r:/run/rootfsbase
        else
            ovlfs=lowerdir=/run/rootfsbase
        fi
        echo "Options=${ROOTFLAGS},${ovlfs},upperdir=/run/overlayfs,workdir=/run/ovlwork"
        echo "Type=overlay"
        _dev=LiveOS_rootfs
    else
        echo "What=/dev/mapper/live-rw"
        [ -n "$ROOTFLAGS" ] && echo "Options=${ROOTFLAGS}"
        _dev=$'dev-mapper-live\\x2drw'
    fi
} > "$GENERATOR_DIR"/sysroot.mount

mkdir -p "$GENERATOR_DIR/$_dev.device.d"
{
    echo "[Unit]"
    echo "JobTimeoutSec=3000"
    echo "JobRunningTimeoutSec=3000"
} > "$GENERATOR_DIR/$_dev.device.d/timeout.conf"
