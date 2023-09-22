#!/bin/sh

type getarg > /dev/null 2>&1 || . /lib/dracut-lib.sh

getargbool 0 rd.live.overlay.overlayfs && overlayfs="yes"
getargbool 0 rd.live.overlay.reset -d -y reset_overlay && reset_overlay="yes"

if [ -n "$overlayfs" ]; then
    if ! [ -e /run/rootfsbase ]; then
        mkdir -m 0755 -p /run/rootfsbase
        mount --bind "$NEWROOT" /run/rootfsbase
    fi

    mkdir -m 0755 -p /run/overlayfs
    mkdir -m 0755 -p /run/ovlwork
    if [ -n "$reset_overlay" ] && [ -h /run/overlayfs ]; then
        ovlfsdir=$(readlink /run/overlayfs)
        info "Resetting the OverlayFS overlay directory."
        rm -r -- "${ovlfsdir:?}"/* "${ovlfsdir:?}"/.* > /dev/null 2>&1
    fi
fi
