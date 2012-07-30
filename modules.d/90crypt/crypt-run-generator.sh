#!/bin/sh

. /lib/dracut-lib.sh

dev=$1
luks=$2

while read l rest; do
    strstr "${l##luks-}" "${luks##luks-}" && exit 0
done < /etc/crypttab


echo "$luks $dev" >> /etc/crypttab
/lib/systemd/system-generators/systemd-cryptsetup-generator
systemctl daemon-reload
systemctl start cryptsetup.target
exit 0
