#!/bin/sh

type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh

[ -z "$root" ] && root=$(getarg root=)

# support legacy syntax of passing liveimg and then just the base root
if getargbool 0 rd.live.image -d -y liveimg; then
    liveroot="live:$root"
fi

if [ "${root%%:*}" = "live" ] ; then
    liveroot=$root
fi

[ "${liveroot%%:*}" = "live" ] || exit 0

case "$liveroot" in
    live:nfs://*|nfs://*) \
        root="${root#live:}"
        rootok=1 ;;
    live:http://*|http://*) \
        root="${root#live:}"
        rootok=1 ;;
    live:https://*|https://*) \
        root="${root#live:}"
        rootok=1 ;;
    live:ftp://*|ftp://*) \
        root="${root#live:}"
        rootok=1 ;;
    live:torrent://*|torrent://*) \
        root="${root#live:}"
        rootok=1 ;;
    live:tftp://*|tftp://*) \
        root="${root#live:}"
        rootok=1 ;;
esac

[ "$rootok" != "1" ] && exit 0

GENERATOR_DIR="$2"
[ -z "$GENERATOR_DIR" ] && exit 1

[ -d "$GENERATOR_DIR" ] || mkdir "$GENERATOR_DIR"

ROOTFLAGS="$(getarg rootflags)"
{
    echo "[Unit]"
    echo "Before=initrd-root-fs.target"
    echo "[Mount]"
    echo "Where=/sysroot"
    echo "What=/dev/mapper/live-rw"
    [ -n "$ROOTFLAGS" ] && echo "Options=${ROOTFLAGS}"
} > "$GENERATOR_DIR"/sysroot.mount

mkdir -p "$GENERATOR_DIR/dev-mapper-live\x2drw.device.d"
{
    echo "[Unit]"
    echo "JobTimeoutSec=3000"
} > "$GENERATOR_DIR/dev-mapper-live\x2drw.device.d/timeout.conf"
