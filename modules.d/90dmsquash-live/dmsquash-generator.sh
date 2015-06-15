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
    live:LABEL=*|LABEL=*) \
        root="${root#live:}"
        root="$(echo $root | sed 's,/,\\x2f,g')"
        root="live:/dev/disk/by-label/${root#LABEL=}"
        rootok=1 ;;
    live:CDLABEL=*|CDLABEL=*) \
        root="${root#live:}"
        root="$(echo $root | sed 's,/,\\x2f,g')"
        root="live:/dev/disk/by-label/${root#CDLABEL=}"
        rootok=1 ;;
    live:UUID=*|UUID=*) \
        root="${root#live:}"
        root="live:/dev/disk/by-uuid/${root#UUID=}"
        rootok=1 ;;
    live:PARTUUID=*|PARTUUID=*) \
        root="${root#live:}"
        root="live:/dev/disk/by-partuuid/${root#PARTUUID=}"
        rootok=1 ;;
    live:PARTLABEL=*|PARTLABEL=*) \
        root="${root#live:}"
        root="live:/dev/disk/by-partlabel/${root#PARTLABEL=}"
        rootok=1 ;;
    live:/*.[Ii][Ss][Oo]|/*.[Ii][Ss][Oo])
        root="${root#live:}"
        root="liveiso:${root}"
        rootok=1 ;;
    live:/dev/*)
        rootok=1 ;;
    live:/*.[Ii][Mm][Gg]|/*.[Ii][Mm][Gg])
        [ -f "${root#live:}" ] && rootok=1 ;;
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
