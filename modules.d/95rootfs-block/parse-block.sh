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
    /dev/*)
	root="block:${root}"
        rootok=1 ;;
esac
