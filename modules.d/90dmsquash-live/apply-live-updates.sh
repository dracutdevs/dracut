#!/bin/sh

. /tmp/root.info

if [ -b /dev/mapper/live-rw ] && [ -d /updates ]; then
    info "Applying updates to live image..."
    # avoid overwriting symlinks (e.g. /lib -> /usr/lib) with directories
    (
        cd /updates
        find . -depth -type d | while read dir; do
            [ -d "$NEWROOT/$dir" ] || mkdir -p "$NEWROOT/$dir"
        done
        find . -depth \! -type d | while read file; do
            cp -a "$file" "$NEWROOT/$file"
        done
    )
fi
