#!/bin/sh
if [ -b /dev/mapper/live-rw ]; then
    if [ "`echo /updates/*`" != "/updates/*" ]; then
        echo "Applying updates to live image..."
        /bin/cp -a /updates/* $NEWROOT
    fi
fi
