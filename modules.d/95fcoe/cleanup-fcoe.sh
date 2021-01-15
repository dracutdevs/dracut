#!/usr/bin/sh

if [ -e /var/run/lldpad.pid ]; then
    lldpad -k
    # with systemd version 230, this is not necessary anymore
    # systemd commit cacf980ed44a28e276a6cc7f8fc41f991e2ab354
    if [ -z "$DRACUT_SYSTEMD" ]; then
        mkdir -m 0755 -p /run/initramfs/state/dev/shm
        cp /dev/shm/lldpad.state /run/initramfs/state/dev/shm/ > /dev/null 2>&1
        echo "files /dev/shm/lldpad.state" >> /run/initramfs/rwtab
    fi
fi
