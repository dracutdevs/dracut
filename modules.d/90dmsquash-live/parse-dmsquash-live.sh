# live images are specified with
# root=live:backingdev

echo "parsing for live"
[ -z "$root" ] && root=$(getarg root=)

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
    live:UUID=*|UUID=*)
	root="${root#live:}"
	root="live:/dev/disk/by-uuid/${root#UUID=}"
        rootok=1 ;;
    /dev/*)
	root="live:${root}"
        rootok=1 ;;
esac
echo "root was $root, liveroot is now $liveroot"


# make sure that init doesn't complain
[ -z "$root" ] && root="live"
