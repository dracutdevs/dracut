#!/bin/sh
[ "$root" ] || {
    root=$(getarg root=)
    case $root in
	LABEL=*) root=${root#LABEL=}
            root="$(echo $root |sed 's,/,\\x2f,g')"
            root="/dev/disk/by-label/${root}" ;;
        UUID=*) root="/dev/disk/by-uuid/${root#UUID=}" ;;
        '') echo "Warning: no root specified"
            root="/dev/sda1" ;;
    esac
}

[ "$rflags" ] || {
    if rflags="$(getarg rootflags=)"; then
	getarg rw && rflags="${rflags},rw" || rflags="${rflags},ro"
    else
	getarg rw && rflags=rw || rflags=ro
    fi
}

[ "$fstype" ] || {
    fstype="$(getarg rootfstype=)" && fstype="-t ${fstype}"
}
