#!/bin/sh

type nm_generate_connections >/dev/null 2>&1 || . /lib/nm-lib.sh

if [ -n "$netroot" ] || [ -e /tmp/net.ifaces ]; then
    echo rd.neednet >> /etc/cmdline.d/35-neednet.conf
fi

if getargbool 0 rd.debug -d -y rdinitdebug -d -y rdnetdebug; then
    mkdir -m 0755 -p /run/NetworkManager/conf.d
    (
        echo '[logging]'
        echo 'level=TRACE'
    ) > /run/NetworkManager/conf.d/initrd-logging.conf
fi

nm_generate_connections
