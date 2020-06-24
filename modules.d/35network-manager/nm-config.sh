#!/bin/sh

type nm_generate_connections >/dev/null 2>&1 || . /lib/nm-lib.sh

if [ -n "$netroot" ] || [ -e /tmp/net.ifaces ]; then
    echo rd.neednet >> /etc/cmdline.d/35-neednet.conf
fi

nm_generate_connections
