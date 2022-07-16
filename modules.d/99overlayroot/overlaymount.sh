#!/bin/bash
OVERLAY=/run/overlayroot

if getargbool 0 overlayroot; then
    info "Overlayroot: Activating Overlayroot"
    if ! mkdir -p $OVERLAY/{u,w,rootfs} && chmod 750 $OVERLAY -R; then
        warn "Overlayroot: overlay folder creation failed"
        return 1
    fi

    info "Overlayroot: Moving sysroot to /run/overlayroot/rootfs"
    if mount --make-private /; then
        if ! mount --move /sysroot $OVERLAY/rootfs; then
            warn "Overlayroot: Moving sysroot failed (2)"
            return 1
        fi
    else
        warn "Overlayroot: Moving sysroot failed (1)"
        return 1
    fi

    info "Overlayroot: Mounting overlay"git@github.com:TylerHelt0/dracut-merge-overlayroot.git
    if ! mount -t overlay overlayroot -o lowerdir=$OVERLAY/rootfs,upperdir=$OVERLAY/u,workdir=$OVERLAY/w /sysroot; then
        warn "Overlayroot mount failed"
        return 1
    fi

    info "Overlayroot mounted successfully probably"
    return 0

else
    info "Overlayroot: not activated. Check cmdline"
    return 0
fi
