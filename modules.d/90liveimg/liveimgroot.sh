#!/bin/sh
# liveimgroot - fetch a live image from the network and run it

type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh

. /lib/url-lib.sh

PATH=/usr/sbin:/usr/bin:/sbin:/bin

# args get passed from 40network/netroot
netroot="$2"
liveurl="${netroot#liveimg:}"
info "fetching $liveurl"
imgfile=$(fetch_url "$liveurl")
[ $? = 0 ] || die "failed to download live image: error $?"

root=$imgfile

exec /sbin/overlayfs-live-root $root
