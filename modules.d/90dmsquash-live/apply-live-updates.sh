#!/bin/sh
if [ -b /dev/mapper/live-rw ]; then
    if pushd /updates &>/dev/null; then
        echo "Applying updates to live image..."
        /bin/cp -a -t $NEWROOT .
        popd &>/dev/null
    fi
fi
