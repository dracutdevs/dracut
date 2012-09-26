#!/bin/sh

. /lib/dracut-lib.sh

dev=$1
luks=$2

if [ -f /etc/crypttab ]; then
    while read l rest; do
        strstr "${l##luks-}" "${luks##luks-}" && exit 0
    done < /etc/crypttab
fi

# parse for allow-discards
if strstr "$(cryptsetup --help)" "allow-discards"; then
    if discarduuids=$(getargs "rd.luks.allow-discards"); then
        if strstr " $discarduuids " " ${luks##luks-}"; then
	    allowdiscards="allow-discards"
	fi
    elif getargbool rd.luks.allow-discards; then
	allowdiscards="allow-discards"
    fi
fi

echo "$luks $dev none $allowdiscards" >> /etc/crypttab
systemctl daemon-reload
systemctl start cryptsetup.target
exit 0
