#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

. /lib/dracut-lib.sh

dev=$1
luks=$2

if [ -f /etc/crypttab ]; then
    while read l rest; do
        strstr "${l##luks-}" "${luks##luks-}" && exit 0
    done < /etc/crypttab
fi

allowdiscards="-"

# parse for allow-discards
if strstr "$(cryptsetup --help)" "allow-discards"; then
    if discarduuids=$(getargs "rd.luks.allow-discards"); then
        discarduuids=$(str_replace "$discarduuids" 'luks-' '')
        if strstr " $discarduuids " " ${luks##luks-}"; then
            allowdiscards="allow-discards"
        fi
    elif getargbool 0 rd.luks.allow-discards; then
        allowdiscards="allow-discards"
    fi
fi

echo "$luks $dev - timeout=0,$allowdiscards" >> /etc/crypttab

if command -v systemctl >/dev/null; then
    systemctl daemon-reload
    systemctl start cryptsetup.target
fi
exit 0
