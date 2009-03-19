#!/bin/sh
if [ ! -s /.resume -a "$root" ]; then
    mount $fstype -o "$rflags" "$root" "$NEWROOT" && ROOTFS_MOUNTED=yes
fi
