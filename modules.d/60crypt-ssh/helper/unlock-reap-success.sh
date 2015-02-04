#!/bin/sh

SYSTEMD_CRYPTSETUP="$(ps -C systemd-cryptsetup -o pid=)"
if [[ $? -eq 0 ]]; then
 # SystemD method
 kill -9 ${SYSTEMD_CRYPTSETUP}
else
 # Older method
 pkill cryptroot-ask
fi

