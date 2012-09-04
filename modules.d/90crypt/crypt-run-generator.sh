#!/bin/sh

. /lib/dracut-lib.sh

dev=$1
luks=$2

if [ -f /etc/crypttab ]; then
    while read l rest; do
        strstr "${l##luks-}" "${luks##luks-}" && exit 0
    done < /etc/crypttab
fi

echo "$luks $dev" >> /etc/crypttab
systemctl daemon-reload
systemctl start cryptsetup.target
exit 0
