#!/bin/sh
if resume=$(getarg resume=) && ! getarg noresume; then 
    export resume
    echo "$resume" >/.resume
else
    unset resume
fi

root=$(getarg root=)
case $root in
    LABEL=*) root=${root#LABEL=}
    root="$(echo $root |sed 's,/,\\x2f,g')"
    root="/dev/disk/by-label/${root}" ;;
    UUID=*) root="/dev/disk/by-uuid/${root#UUID=}" ;;
    '') echo "Warning: no root specified"
        root="/dev/sda1" ;;
esac

if rflags="$(getarg rootflags=)"; then
    getarg rw && rflags="${rflags},rw" || rflags="${rflags},ro"
else
    getarg rw && rflags=rw || rflags=ro
fi

fstype="$(getarg rootfstype=)" && fstype="-t ${fstype}"

export fstype rflags root
