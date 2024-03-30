#!/bin/sh
# livenetroot - fetch a live image from the network and run it

type getarg > /dev/null 2>&1 || . /lib/dracut-lib.sh

. /lib/url-lib.sh

PATH=/usr/sbin:/usr/bin:/sbin:/bin
RETRIES=${RETRIES:-100}
SLEEP=${SLEEP:-5}

[ -e /tmp/livenet.downloaded ] && exit 0

# args get passed from 40network/netroot
netroot="$2"
liveurl="${netroot#livenet:}"
info "fetching $liveurl"

if getargbool 0 'rd.writable.fsimg'; then
    imgheader=$(curl -sIL "$liveurl")

    # shellcheck disable=SC2181
    ret=$?
    if [ $ret != 0 ]; then
        warn "failed to get live image header: error $ret"
    else
        imgheaderlen=$(echo "$imgheader" | sed -n 's/[cC]ontent-[lL]ength: *\([[:digit:]]*\).*/\1/p')
        if [ -z "$imgheaderlen" ]; then
            warn "failed to get 'Content-Length' header from live image"
        else
            imgsize=$((imgheaderlen / (1024 * 1024)))
            check_live_ram $imgsize
        fi
    fi
fi

imgfile=
#retry until the imgfile is populated with data or the max retries
i=1
while [ "$i" -le "$RETRIES" ]; do
    imgfile=$(fetch_url "$liveurl")

    # shellcheck disable=SC2181
    ret=$?
    if [ $ret != 0 ]; then
        warn "failed to download live image: error $ret"
        imgfile=
    fi

    if [ -n "$imgfile" -a -s "$imgfile" ]; then
        break
    else
        if [ $i -ge "$RETRIES" ]; then
            warn "failed to download live image after $i attempts."
            exit 1
        fi

        sleep "$SLEEP"
    fi

    i=$((i + 1))
done > /tmp/livenet.downloaded

# TODO: couldn't dmsquash-live-root handle this?
if [ "${imgfile##*.}" = "iso" ]; then
    root=$(losetup -f)
    losetup "$root" "$imgfile"
else
    root=$imgfile
fi

exec /sbin/dmsquash-live-root "$root"
