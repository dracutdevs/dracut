#!/bin/sh

if [ -n "$netroot" ] || [ -e /tmp/net.ifaces ]; then
    echo rd.neednet >> /etc/cmdline.d/35-neednet.conf
fi

/usr/libexec/nm-initrd-generator -- $(getcmdline)

if getargbool 0 rd.neednet; then
  for i in /usr/lib/NetworkManager/system-connections/* \
           /run/NetworkManager/system-connections/* \
           /etc/NetworkManager/system-connections/* \
           /etc/sysconfig/network-scripts/ifcfg-*; do
    [ -f "$i" ] || continue
    echo '[ -f /tmp/nm.done ]' >$hookdir/initqueue/finished/nm.sh
    break
  done
fi
