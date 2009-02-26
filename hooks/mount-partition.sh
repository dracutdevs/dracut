#!/bin/sh
[ "$root" ] || {
    root=$(getarg root); root=${root#root=}
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
    if rflags="$(getarg rootflags)"; then
	rflags="${rflags#rootflags=}"
	getarg rw >/dev/null && rflags="${rflags},rw" || rflags="${rflags},ro"
    else
	getarg rw >/dev/null && rflags=rw || rflags=ro
    fi
}

[ "$fstype" ] || {
    fstype="$(getarg rootfstype)" && fstype="-t ${fstype#rootfstype=}"
}

[ -e "$root" ] && {
    ln -sf "$root" /dev/root
    mount $fstype -o $rflags /dev/root $NEWROOT && ROOTFS_MOUNTED=yes
}
