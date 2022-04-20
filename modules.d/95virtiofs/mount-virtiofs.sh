#!/usr/bin/sh

if [ "${fstype}" = "virtiofs" -o "${root%%:*}" = "virtiofs" ]; then
    if ! { modprobe virtiofs || strstr "$(cat /proc/filesystems)" virtiofs; }; then
        die "virtiofs is required but not available."
    fi

    mount -t virtiofs -o "$rflags" "${root#virtiofs:}" "$NEWROOT" 2>&1 | vinfo
    if ! ismounted "$NEWROOT"; then
        die "virtiofs: failed to mount root fs"
        exit 1
    fi

    info "virtiofs: root fs mounted (options: '${rflags}')"

    [ -f "$NEWROOT"/forcefsck ] && rm -f -- "$NEWROOT"/forcefsck 2> /dev/null
    [ -f "$NEWROOT"/.autofsck ] && rm -f -- "$NEWROOT"/.autofsck 2> /dev/null
fi
:
