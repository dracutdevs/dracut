#!/bin/sh
# live images are specified with
# root=live:backingdev

[ -z "$root" ] && root=$(getarg root=)

# support legacy syntax of passing liveimg and then just the base root
if getarg liveimg; then
    liveroot="live:$root"
fi

if [ "${root%%:*}" = "live" ] ; then
    liveroot=$root
fi

[ "${liveroot%%:*}" = "live" ] || return

case "$liveroot" in
    live:LABEL=*|LABEL=*)
	root="${root#live:}"
	root="$(echo $root | sed 's,/,\\x2f,g')"
	root="live:/dev/disk/by-label/${root#LABEL=}"
        rootok=1 ;;
    live:CDLABEL=*|CDLABEL=*)
	root="${root#live:}"
	root="$(echo $root | sed 's,/,\\x2f,g')"
	root="live:/dev/disk/by-label/${root#CDLABEL=}"
        rootok=1 ;;
    live:UUID=*|UUID=*)
	root="${root#live:}"
	root="live:/dev/disk/by-uuid/${root#UUID=}"
        rootok=1 ;;
    live:/*.[Ii][Ss][Oo]|/*.[Ii][Ss][Oo])
	root="${root#live:}"
	root="liveiso:${root}"
	rootok=1 ;;
    live:/dev/*)
        rootok=1 ;;
esac
info "root was $root, liveroot is now $liveroot"

[ $rootok = "1" ] && initqueue --settled /sbin/cdrom-hack.sh

# make sure that init doesn't complain
[ -z "$root" ] && root="live"
