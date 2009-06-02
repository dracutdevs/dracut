#!/bin/sh
if [ ! -s /.resume -a -n "$root" -a -z "${root%%block:*}" ]; then
    mount -t ${fstype:-auto} -o "$rflags" "${root#block:}" "$NEWROOT" && ROOTFS_MOUNTED=yes
fi
