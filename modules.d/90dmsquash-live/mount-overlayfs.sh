#!/bin/sh

type getarg > /dev/null 2>&1 || . /lib/dracut-lib.sh

PATH=/usr/sbin:/usr/bin:/sbin:/bin

getargbool 0 rd.live.overlay.overlayfs && overlayfs="yes"
getargbool 0 rd.live.overlay.reset -d -y reset_overlay && reset_overlay="yes"
getargbool 0 rd.live.overlay.readonly -d -y readonly_overlay && readonly_overlay="--readonly" || readonly_overlay=""

ROOTFLAGS="$(getarg rootflags)"

if [ -n "$overlayfs" ]; then
    if ! [ -e /run/rootfsbase ]; then
        mkdir -m 0755 -p /run/rootfsbase
        mount --bind "$NEWROOT" /run/rootfsbase
    fi

    mkdir -m 0755 -p /run/overlayfs
    mkdir -m 0755 -p /run/ovlwork
    if [ -n "$reset_overlay" ] && [ -h /run/overlayfs ]; then
        ovlfs=$(readlink /run/overlayfs)
        info "Resetting the OverlayFS overlay directory."
        rm -r -- "${ovlfs:?}"/* "${ovlfs:?}"/.* > /dev/null 2>&1
    fi
    if [ -n "$readonly_overlay" ] && [ -h /run/overlayfs-r ]; then
        ovlfs=lowerdir=/run/overlayfs-r:/run/rootfsbase
    else
        ovlfs=lowerdir=/run/rootfsbase
    fi

    if ! strstr "$(cat /proc/mounts)" LiveOS_rootfs; then
        mount -t overlay LiveOS_rootfs -o "$ROOTFLAGS,$ovlfs",upperdir=/run/overlayfs,workdir=/run/ovlwork "$NEWROOT"
    fi
fi
