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
        rootok=1 ;;
esac

root="livenet" # quiet complaints from init
echo '[ -e /dev/root ]' > $hookdir/initqueue/finished/livenet.sh
