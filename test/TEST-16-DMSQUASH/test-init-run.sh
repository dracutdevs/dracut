#!/bin/sh

if grep -qF ' rd.live.overlay=LABEL=persist ' /proc/cmdline; then
    # Writing to a file in the root filesystem lets test_run() verify that the autooverlay module successfully created
    # and formatted the overlay partition and that the dmsquash-live module used it when setting up the rootfs overlay.
    echo "dracut-autooverlay-success" > /overlay-marker
fi
