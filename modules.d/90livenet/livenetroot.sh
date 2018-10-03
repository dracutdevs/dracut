#!/bin/sh
# livenetroot - fetch a live image from the network and run it

type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh

. /lib/url-lib.sh

PATH=/usr/sbin:/usr/bin:/sbin:/bin
RETRIES={RETRIES:-100}
SLEEP={SLEEP:-5}

[ -e /tmp/livenet.downloaded ] && exit 0

# args get passed from 40network/netroot
netroot="$2"
liveurl="${netroot#livenet:}"
info "fetching $liveurl"

imgfile=
#retry until the imgfile is populated with data or the max retries
for (( i=1; i<=$RETRIES; i++))
do
    imgfile=$(fetch_url "$liveurl")

    if [ $? != 0 ]; then
            warn "failed to download live image: error $?"
            imgfile=
    fi

    if [ ! -z "$imgfile" -a -s "$imgfile" ]; then
        break
    else
        sleep $SLEEP
    fi
done > /tmp/livenet.downloaded

# TODO: couldn't dmsquash-live-root handle this?
if [ ${imgfile##*.} = "iso" ]; then
    root=$(losetup -f)
    losetup $root $imgfile
else
    root=$imgfile
fi

exec /sbin/dmsquash-live-root $root
