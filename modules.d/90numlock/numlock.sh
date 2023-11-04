#!/usr/bin/sh
i=1
while [ "${i}" -le 6 ]; do
    setleds -D +num < /dev/tty"${i}"
    i=$((i + 1))
done
