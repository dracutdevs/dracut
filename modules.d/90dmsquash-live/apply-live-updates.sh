#!/bin/sh

if [ -b /dev/mapper/live-rw ] && [ -d /updates ]; then
    info "Applying updates to live image..."
    mount -o bind /run $NEWROOT/run
    # avoid overwriting symlinks (e.g. /lib -> /usr/lib) with directories
    (
        cd /updates
        find . -depth -type d | while read dir; do
            mkdir -p "$NEWROOT/$dir"
        done
        find . -depth \! -type d | while read file; do
            cp -a "$file" "$NEWROOT/$file"
        done
    )
    umount $NEWROOT/run
fi
