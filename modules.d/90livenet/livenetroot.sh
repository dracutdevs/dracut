#!/bin/sh
# livenetroot - fetch a live image from the network and run it

type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh

. /lib/url-lib.sh
. /lib/img-lib.sh

PATH=/usr/sbin:/usr/bin:/sbin:/bin

# args get passed from 40network/netroot
netroot="$2"
liveurl="${netroot#livenet:}"
info "fetching $liveurl"
imgfile=$(fetch_url "$liveurl")

[ $? = 0 ] || die "failed to download live image: error $?"

unpack_archive $imgfile $imgfile.new

mv  $imgfile.new $imgfile


# TODO: couldn't dmsquash-live-root handle this?
if [ ${imgfile##*.} = "iso" ]; then
    root=$(losetup -f)
    losetup $root $imgfile
else
    root=$imgfile
fi

exec /sbin/dmsquash-live-root $root
