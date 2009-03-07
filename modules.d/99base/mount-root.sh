#!/bin/sh
[ "$root" ] && mount $fstype -o "$rflags" "$root" "$NEWROOT" && \
    ROOTFS_MOUNTED=yes
