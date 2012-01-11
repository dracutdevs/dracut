#!/bin/bash
# live net images - just like live images, but specified like:
# root=live:[url-to-backing-file]

[ -z "$root" ] && root=$(getarg root=)

str_starts $root "live:" && liveurl=$root
str_starts $liveurl "live:" || return
liveurl="${liveurl#live:}"

# setting netroot to "livenet:..." makes "livenetroot" get run after ifup
case "$liveurl" in
    http://*|https://*|ftp://*)
        netroot="livenet:$liveurl"
        root="livenet" # quiet complaints from init
        rootok=1 ;;
esac

wait_for_dev /dev/root
