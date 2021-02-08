#!/bin/sh

type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh

containers=""
for md in /dev/md[0-9_]*; do
    [ -b "$md" ] || continue
    udevinfo="$(udevadm info --query=env --name=$md)"
    strstr "$udevinfo" "DEVTYPE=partition" && continue
    if strstr "$udevinfo" "MD_LEVEL=container"; then
        containers="$containers $md"
        continue
    fi
    mdadm -S "$md" >/dev/null 2>&1
done

for md in $containers; do
    mdadm -S "$md" >/dev/null 2>&1
done

unset containers udevinfo
