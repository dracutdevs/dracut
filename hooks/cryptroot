#!/bin/sh
[ -f /cryptroot ] && { 
    echo "Encrypted root detected."
    read cryptopts </cryptroot
    /sbin/cryptsetup luksOpen $cryptopts || emergency_shell
    udevadm settle --timeout=30
}
