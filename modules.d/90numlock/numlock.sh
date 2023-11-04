#!/usr/bin/sh
i=1
# 6 is the default value of the NAutoVTs option of the systemd login manager
while [ "${i}" -le 6 ]; do
    setleds -D +num < /dev/tty"${i}"
    i=$((i + 1))
done
