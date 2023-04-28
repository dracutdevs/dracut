#!/bin/sh
. /lib/dracut-lib.sh

if ! [ "$DEBUG_MEM_LEVEL" -ge 4 ]; then
    return 0
fi

if command -v systemctl > /dev/null; then
    systemctl stop memstrack.service
else
    pkill --signal INT '[m]emstrack'
    while pgrep -c '[m]emstrack' > /dev/null; do
        sleep 1
    done
fi

if ! [ -e /proc/vmcore ]; then
    if [ -e /.memstrack ]; then
        IFS= vwarn < /.memstrack
    else
        warn 'No memstrack log generated!'
   fi
fi
