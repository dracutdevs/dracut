#!/bin/sh
# live net images - just like live images, but specified like:
# root=live:[url-to-backing-file]

[ -z "$root" ] && root=$(getarg root=)
. /lib/url-lib.sh

str_starts "$root" "live:" && liveurl="$root"
str_starts "$liveurl" "live:" || return
liveurl="${liveurl#live:}"

# setting netroot to "livenet:..." makes "livenetroot" get run after ifup
if get_url_handler "$liveurl" >/dev/null; then
    info "liveimg: root image at $liveurl"
    netroot="liveimg:$liveurl"
    root="liveimg" # quiet complaints from init
    rootok=1
    wait_for_mount /
else
    info "liveimg: no url handler for $liveurl"
fi
