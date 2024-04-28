#!/bin/sh

type getarg > /dev/null 2>&1 || . /lib/dracut-lib.sh

getargbool 0 rd.live.overlay.overlayfs && overlayfs="yes"
getargbool 0 rd.live.overlay.readonly -d -y readonly_overlay && readonly_overlay="--readonly" || readonly_overlay=""

ROOTFLAGS="$(getarg rootflags)"

if [ -n "$overlayfs" ]; then
    if [ -n "$readonly_overlay" ] && [ -h /run/overlayfs-r ]; then
        if [ -n ${join} ]; then
            ovlfs=lowerdir=/run/overlayfs-r:/run/rootfsjoin:/run/rootfsbase
        else
            ovlfs=lowerdir=/run/overlayfs-r:/run/rootfsbase
        fi
    else
        if [ -n ${join} ]; then
            ovlfs=lowerdir=/run/rootfsjoin:/run/rootfsbase
        else
            ovlfs=lowerdir=/run/rootfsbase
        fi
    fi

    if ! strstr "$(cat /proc/mounts)" LiveOS_rootfs; then
        mount -t overlay LiveOS_rootfs -o "$ROOTFLAGS,$ovlfs",upperdir=/run/overlayfs,workdir=/run/ovlwork "$NEWROOT"
    fi
fi
