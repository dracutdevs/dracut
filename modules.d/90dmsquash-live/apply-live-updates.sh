#!/bin/sh
if [ -b /dev/mapper/live-rw ]; then
    if [ -d /updates ]; then
        echo "Applying updates to live image..."
        cd /updates
        /bin/cp -a -t $NEWROOT .
        cd -
    fi
fi
