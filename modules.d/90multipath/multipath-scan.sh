#!/bin/sh

# scan for multipaths if udev has settled

. /lib/dracut-lib.sh

[ -d /etc/multipath ] || mkdir -p /etc/multipath
mpdevs=$(
    for f in /tmp/.multipath-scan-* ; do
        [ -e "$f" ] || continue
        echo -n "${f##/tmp/.multipath-scan-} "
    done
)

[ -e /etc/multipath.conf ] || exit 1
multipath ${mpdevs}
