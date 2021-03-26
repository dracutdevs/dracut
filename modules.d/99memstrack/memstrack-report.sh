#!/bin/bash
. /lib/dracut-lib.sh

if ! [ "$DEBUG_MEM_LEVEL" -ge 4 ]; then
    return 0
fi

if type -P systemctl > /dev/null; then
    systemctl stop memstrack.service
else
    pkill --signal INT '[m]emstrack'
    while [[ $(pgrep '[m]emstrack') ]]; do
        sleep 1
    done
fi

cat /.memstrack
