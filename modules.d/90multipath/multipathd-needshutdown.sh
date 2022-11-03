#!/bin/sh

type need_shutdown > /dev/null 2>&1 || . /lib/dracut-lib.sh

for i in $(multipath -l -v1); do
    if dmsetup table "$i" | sed -n '/.*queue_if_no_path.*/q1'; then
        need_shutdown
        break
    fi
done
