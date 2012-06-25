#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh

PATH=/usr/sbin:/usr/bin:/sbin:/bin

if getargbool 0 rd.live.debug -y rdlivedebug; then
    exec > /tmp/liveroot.$$.out
    exec 2>> /tmp/liveroot.$$.out
    set -x
fi

[ -z "$1" ] && exit 1
livedev="$1"

# parse various live image specific options that make sense to be
# specified as their own things
live_dir=$(getarg rd.live.dir live_dir)
[ -z "$live_dir" ] && live_dir="LiveOS"
getargbool 0 rd.live.ram -y live_ram && live_ram="yes"
getargbool 0 rd.live.overlay.reset -y reset_overlay && reset_overlay="yes"
getargbool 0 rd.live.overlay.readonly -y readonly_overlay && readonly_overlay="--readonly" || readonly_overlay=""
overlay=$(getarg rd.live.overlay overlay)

# CD/DVD media check
[ -b $livedev ] && fs=$(blkid -s TYPE -o value $livedev)
if [ "$fs" = "iso9660" -o "$fs" = "udf" ]; then
    check="yes"
fi
getarg rd.live.check check || check=""
if [ -n "$check" ]; then
    [ -x /bin/plymouth ] && /bin/plymouth --hide-splash
    checkisomd5 --verbose $livedev
    if [ $? -ne 0 ]; then
        die "CD check failed!"
        exit 1
    fi
    [ -x /bin/plymouth ] && /bin/plymouth --show-splash
fi

ln -s $livedev /run/initramfs/livedev

# determine filesystem type for a filesystem image
det_img_fs() {
    blkid -s TYPE -u noraid -o value "$1"
}

for arg in $CMDLINE; do case $arg in ro|rw) liverw=$arg ;; esac; done
# mount the backing of the live image first
mkdir -m 0755 -p /run/initramfs/live
if [ -f $livedev ]; then
    # no mount needed - we've already got the LiveOS image in initramfs
    # check filesystem type and handle accordingly
    fstype=$(det_img_fs $livedev)
    case $fstype in
        squashfs) SQUASHED=$livedev;;
        auto) die "cannot mount live image (unknown filesystem type)" ;;
        *) FSIMG=$livedev ;;
    esac
    [ -e /sys/fs/$fstype ] || modprobe $fstype
else
    mount -n -t $fstype -o ${liverw:-ro} $livedev /run/initramfs/live
    if [ "$?" != "0" ]; then
        die "Failed to mount block device of live image"
        exit 1
    fi
fi

# overlay setup helper function
do_live_overlay() {
    # create a sparse file for the overlay
    # overlay: if non-ram overlay searching is desired, do it,
    #              otherwise, create traditional overlay in ram
    OVERLAY_LOOPDEV=$( losetup -f )

    l=$(blkid -s LABEL -o value $livedev) || l=""
    u=$(blkid -s UUID -o value $livedev) || u=""

    if [ -z "$overlay" ]; then
        pathspec="/${live_dir}/overlay-$l-$u"
    elif ( echo $overlay | grep -q ":" ); then
        # pathspec specified, extract
        pathspec=$( echo $overlay | sed -e 's/^.*://' )
    fi

    if [ -z "$pathspec" -o "$pathspec" = "auto" ]; then
        pathspec="/${live_dir}/overlay-$l-$u"
    fi
    devspec=$( echo $overlay | sed -e 's/:.*$//' )

    # need to know where to look for the overlay
    setup=""
    if [ -n "$devspec" -a -n "$pathspec" -a -n "$overlay" ]; then
        mkdir -m 0755 /run/initramfs/overlayfs
        mount -n -t auto $devspec /run/initramfs/overlayfs || :
        if [ -f /run/initramfs/overlayfs$pathspec -a -w /run/initramfs/overlayfs$pathspec ]; then
            losetup $OVERLAY_LOOPDEV /run/initramfs/overlayfs$pathspec
            if [ -n "$reset_overlay" ]; then
                dd if=/dev/zero of=$OVERLAY_LOOPDEV bs=64k count=1 2>/dev/null
            fi
            setup="yes"
        fi
        umount -l /run/initramfs/overlayfs || :
    fi

    if [ -z "$setup" ]; then
        if [ -n "$devspec" -a -n "$pathspec" ]; then
            warn "Unable to find persistent overlay; using temporary"
            sleep 5
        fi

        dd if=/dev/null of=/overlay bs=1024 count=1 seek=$((512*1024)) 2> /dev/null
        losetup $OVERLAY_LOOPDEV /overlay
    fi

    # set up the snapshot
    echo 0 `blockdev --getsz $BASE_LOOPDEV` snapshot $BASE_LOOPDEV $OVERLAY_LOOPDEV p 8 | dmsetup create $readonly_overlay live-rw
}

# live cd helper function
do_live_from_base_loop() {
    do_live_overlay
}

# we might have a genMinInstDelta delta file for anaconda to take advantage of
if [ -e /run/initramfs/live/${live_dir}/osmin.img ]; then
    OSMINSQFS=/run/initramfs/live/${live_dir}/osmin.img
fi

if [ -n "$OSMINSQFS" ]; then
    # decompress the delta data
    dd if=$OSMINSQFS of=/osmin.img 2> /dev/null
    OSMIN_SQUASHED_LOOPDEV=$( losetup -f )
    losetup -r $OSMIN_SQUASHED_LOOPDEV /osmin.img
    mkdir -m 0755 -p /run/initramfs/squashfs.osmin
    mount -n -t squashfs -o ro $OSMIN_SQUASHED_LOOPDEV /run/initramfs/squashfs.osmin
    OSMIN_LOOPDEV=$( losetup -f )
    losetup -r $OSMIN_LOOPDEV /run/initramfs/squashfs.osmin/osmin
    umount -l /run/initramfs/squashfs.osmin
fi

# we might have an embedded fs image to use as rootfs (uncompressed live)
if [ -e /run/initramfs/live/${live_dir}/ext3fs.img ]; then
    FSIMG="/run/initramfs/live/${live_dir}/ext3fs.img"
elif [ -e /run/initramfs/live/${live_dir}/rootfs.img ]; then
    FSIMG="/run/initramfs/live/${live_dir}/rootfs.img"
fi

if [ -n "$FSIMG" ] ; then
    BASE_LOOPDEV=$( losetup -f )
    losetup -r $BASE_LOOPDEV $FSIMG

    do_live_from_base_loop
fi

# we might have an embedded fs image on squashfs (compressed live)
if [ -e /run/initramfs/live/${live_dir}/squashfs.img ]; then
    SQUASHED="/run/initramfs/live/${live_dir}/squashfs.img"
fi

if [ -e "$SQUASHED" ] ; then
    if [ -n "$live_ram" ] ; then
        echo "Copying live image to RAM..."
        echo "(this may take a few minutes)"
        dd if=$SQUASHED of=/squashed.img bs=512 2> /dev/null
        umount -n /run/initramfs/live
        echo "Done copying live image to RAM."
        eject -p $livedev || :
        SQUASHED="/squashed.img"
    fi

    SQUASHED_LOOPDEV=$( losetup -f )
    losetup -r $SQUASHED_LOOPDEV $SQUASHED
    mkdir -m 0755 -p /run/initramfs/squashfs
    mount -n -t squashfs -o ro $SQUASHED_LOOPDEV /run/initramfs/squashfs

    BASE_LOOPDEV=$( losetup -f )
    if [ -f /run/initramfs/squashfs/LiveOS/ext3fs.img ]; then
        losetup -r $BASE_LOOPDEV /run/initramfs/squashfs/LiveOS/ext3fs.img
    elif [ -f /run/initramfs/squashfs/LiveOS/rootfs.img ]; then
        losetup -r $BASE_LOOPDEV /run/initramfs/squashfs/LiveOS/rootfs.img
    fi

    umount -l /run/initramfs/squashfs

    do_live_from_base_loop
fi

if [ -b "$OSMIN_LOOPDEV" ]; then
    # set up the devicemapper snapshot device, which will merge
    # the normal live fs image, and the delta, into a minimzied fs image
    echo "0 $( blockdev --getsz $BASE_LOOPDEV ) snapshot $BASE_LOOPDEV $OSMIN_LOOPDEV p 8" | dmsetup create --readonly live-osimg-min
fi

ROOTFLAGS="$(getarg rootflags)"
if [ -n "$ROOTFLAGS" ]; then
    ROOTFLAGS="-o $ROOTFLAGS"
fi

if [ -b "$BASE_LOOPDEV" ]; then
    ln -s $BASE_LOOPDEV /run/initramfs/live-baseloop
fi
ln -s /dev/mapper/live-rw /dev/root
printf 'mount %s /dev/mapper/live-rw %s\n' "$ROOTFLAGS" "$NEWROOT" > $hookdir/mount/01-$$-live.sh

need_shutdown

exit 0
