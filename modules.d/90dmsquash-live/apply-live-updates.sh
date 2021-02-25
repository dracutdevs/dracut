#!/bin/sh

if [ -h /dev/root ] && [ -d /run/initramfs/live/updates -o -d /updates ]; then
    info "Applying updates to live image..."
    mount -o bind /run "$NEWROOT"/run
    # avoid overwriting symlinks (e.g. /lib -> /usr/lib) with directories
    for d in /updates /run/initramfs/live/updates; do
        [ -d "$d" ] || continue
        (
            cd "$d" || return 0
            find . -depth -type d -exec mkdir -p "$NEWROOT/{}" \;
            find . -depth \! -type d -exec cp -a "{}" "$NEWROOT/{}" \;
        )
    done
    umount "$NEWROOT"/run
fi
# release resources on iso-scan boots with rd.live.ram
if [ -d /run/initramfs/isoscan ] \
    && [ -f /run/initramfs/squashed.img -o -f /run/initramfs/rootfs.img ]; then
    umount --detach-loop /run/initramfs/live
    umount /run/initramfs/isoscan
fi
