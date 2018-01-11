#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh

command -v unpack_archive >/dev/null || . /lib/img-lib.sh

PATH=/usr/sbin:/usr/bin:/sbin:/bin

if getargbool 0 rd.live.debug -n -y rdlivedebug; then
    exec > /tmp/liveroot.$$.out
    exec 2>> /tmp/liveroot.$$.out
    set -x
fi

[ -z "$1" ] && exit 1
livedev="$1"

# parse various live image specific options that make sense to be
# specified as their own things
live_dir=$(getarg rd.live.dir -d live_dir)
[ -z "$live_dir" ] && live_dir="LiveOS"
squash_image=$(getarg rd.live.squashimg)
[ -z "$squash_image" ] && squash_image="squashfs.img"

getargbool 0 rd.live.ram -d -y live_ram && live_ram="yes"
getargbool 0 rd.live.overlay.reset -d -y reset_overlay && reset_overlay="yes"
getargbool 0 rd.live.overlay.readonly -d -y readonly_overlay && readonly_overlay="--readonly" || readonly_overlay=""
overlay=$(getarg rd.live.overlay -d overlay)
getargbool 0 rd.writable.fsimg -d -y writable_fsimg && writable_fsimg="yes"
overlay_size=$(getarg rd.live.overlay.size=)
[ -z "$overlay_size" ] && overlay_size=512

getargbool 0 rd.live.overlay.thin && thin_snapshot="yes"

# CD/DVD media check
[ -b $livedev ] && fs=$(blkid -s TYPE -o value $livedev)
if [ "$fs" = "iso9660" -o "$fs" = "udf" ]; then
    check="yes"
fi
getarg rd.live.check -d check || check=""
if [ -n "$check" ]; then
    type plymouth >/dev/null 2>&1 && plymouth --hide-splash
    if [ -n "$DRACUT_SYSTEMD" ]; then
        p=$(str_replace "$livedev" "-" '\x2d')
        systemctl start checkisomd5@${p}.service
    else
        checkisomd5 --verbose $livedev
    fi
    if [ $? -eq 1 ]; then
        die "CD check failed!"
        exit 1
    fi
    type plymouth >/dev/null 2>&1 && plymouth --show-splash
fi

ln -s $livedev /run/initramfs/livedev

# determine filesystem type for a filesystem image
det_img_fs() {
    udevadm settle
    blkid -s TYPE -u noraid -o value "$1"
}

modprobe squashfs
CMDLINE=$(getcmdline)
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
    if [ "$(blkid -o value -s TYPE $livedev)" != "ntfs" ]; then
        mount -n -t $fstype -o ${liverw:-ro} $livedev /run/initramfs/live
    else
        # Symlinking /usr/bin/ntfs-3g as /sbin/mount.ntfs seems to boot
        # at the first glance, but ends with lots and lots of squashfs
        # errors, because systemd attempts to kill the ntfs-3g process?!
        if [ -x "/usr/bin/ntfs-3g" ]; then
            ( exec -a @ntfs-3g ntfs-3g -o ${liverw:-ro} $livedev /run/initramfs/live ) | vwarn
        else
            die "Failed to mount block device of live image: Missing NTFS support"
            exit 1
        fi
    fi

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
                dd if=/dev/zero of=$OVERLAY_LOOPDEV bs=64k count=1 conv=fsync 2>/dev/null
            fi
            setup="yes"
        fi
        umount -l /run/initramfs/overlayfs || :
    fi

    if [ -z "$setup" -o -n "$readonly_overlay" ]; then
        if [ -n "$setup" ]; then
            warn "Using temporary overlay."
        elif [ -n "$devspec" -a -n "$pathspec" ]; then
            warn "Unable to find persistent overlay; using temporary"
            sleep 5
        fi

        dd if=/dev/null of=/overlay bs=1024 count=1 seek=$((overlay_size*1024)) 2> /dev/null
        if [ -n "$setup" -a -n "$readonly_overlay" ]; then
            RO_OVERLAY_LOOPDEV=$( losetup -f )
            losetup $RO_OVERLAY_LOOPDEV /overlay
        else
            losetup $OVERLAY_LOOPDEV /overlay
        fi
    fi

    # set up the snapshot
    sz=$(blockdev --getsz $BASE_LOOPDEV)
    if [ -n "$readonly_overlay" ]; then
        echo 0 $sz snapshot $BASE_LOOPDEV $OVERLAY_LOOPDEV p 8 | dmsetup create $readonly_overlay live-ro
        base="/dev/mapper/live-ro"
        over=$RO_OVERLAY_LOOPDEV
    else
        base=$BASE_LOOPDEV
        over=$OVERLAY_LOOPDEV
    fi

    if [ -n "$thin_snapshot" ]; then
        modprobe dm_thin_pool
        mkdir /run/initramfs/thin-overlay

        # In block units (512b)
        thin_data_sz=$(( $overlay_size * 1024 * 1024 / 512 ))
        thin_meta_sz=$(( $thin_data_sz / 10 ))

        # It is important to have the backing file on a tmpfs
        # this is needed to let the loopdevice support TRIM
        dd if=/dev/null of=/run/initramfs/thin-overlay/meta bs=1b count=1 seek=$((thin_meta_sz)) 2> /dev/null
        dd if=/dev/null of=/run/initramfs/thin-overlay/data bs=1b count=1 seek=$((thin_data_sz)) 2> /dev/null

        THIN_META_LOOPDEV=$( losetup --show -f /run/initramfs/thin-overlay/meta )
        THIN_DATA_LOOPDEV=$( losetup --show -f /run/initramfs/thin-overlay/data )

        echo 0 $thin_data_sz thin-pool $THIN_META_LOOPDEV $THIN_DATA_LOOPDEV 1024 1024 | dmsetup create live-overlay-pool
        dmsetup message /dev/mapper/live-overlay-pool 0 "create_thin 0"

        # Create a snapshot of the base image
        echo 0 $sz thin /dev/mapper/live-overlay-pool 0 $base | dmsetup create live-rw
    else
        echo 0 $sz snapshot $base $over p 8 | dmsetup create live-rw
    fi

    # Create a device that always points to a ro base image
    echo 0 $sz linear $base 0 | dmsetup create --readonly live-base
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
    dd if=$OSMINSQFS of=/run/initramfs/osmin.img 2> /dev/null
    OSMIN_SQUASHED_LOOPDEV=$( losetup -f )
    losetup -r $OSMIN_SQUASHED_LOOPDEV /run/initramfs/osmin.img
    mkdir -m 0755 -p /run/initramfs/squashfs.osmin
    mount -n -t squashfs -o ro $OSMIN_SQUASHED_LOOPDEV /run/initramfs/squashfs.osmin
    OSMIN_LOOPDEV=$( losetup -f )
    losetup -r $OSMIN_LOOPDEV /run/initramfs/squashfs.osmin/osmin
    umount -l /run/initramfs/squashfs.osmin
fi

# we might have an embedded fs image on squashfs (compressed live)
if [ -e /run/initramfs/live/${live_dir}/${squash_image} ]; then
    SQUASHED="/run/initramfs/live/${live_dir}/${squash_image}"
fi

if [ -e "$SQUASHED" ] ; then
    if [ -n "$live_ram" ] ; then
        echo "Copying live image to RAM..."
        echo "(this may take a few minutes)"
        dd if=$SQUASHED of=/run/initramfs/squashed.img bs=512 2> /dev/null
        umount -n /run/initramfs/live
        echo "Done copying live image to RAM."
        SQUASHED="/run/initramfs/squashed.img"
    fi

    SQUASHED_LOOPDEV=$( losetup -f )
    losetup -r $SQUASHED_LOOPDEV $SQUASHED
    mkdir -m 0755 -p /run/initramfs/squashfs
    mount -n -t squashfs -o ro $SQUASHED_LOOPDEV /run/initramfs/squashfs

fi

# we might have an embedded fs image to use as rootfs (uncompressed live)
if [ -e /run/initramfs/live/${live_dir}/ext3fs.img ]; then
    FSIMG="/run/initramfs/live/${live_dir}/ext3fs.img"
elif [ -e /run/initramfs/live/${live_dir}/rootfs.img ]; then
    FSIMG="/run/initramfs/live/${live_dir}/rootfs.img"
elif [ -f /run/initramfs/squashfs/LiveOS/ext3fs.img ]; then
    FSIMG="/run/initramfs/squashfs/LiveOS/ext3fs.img"
elif [ -f /run/initramfs/squashfs/LiveOS/rootfs.img ]; then
    FSIMG="/run/initramfs/squashfs/LiveOS/rootfs.img"
fi

if [ -n "$FSIMG" ] ; then
    BASE_LOOPDEV=$( losetup -f )

    if [ -n "$writable_fsimg" ] ; then
        # mount the provided fileysstem read/write
        echo "Unpacking live filesystem (may take some time)"
        mkdir /run/initramfs/fsimg/
        if [ -n "$SQUASHED" ]; then
            cp -v $FSIMG /run/initramfs/fsimg/rootfs.img
        else
            unpack_archive $FSIMG /run/initramfs/fsimg/
        fi
        losetup $BASE_LOOPDEV /run/initramfs/fsimg/rootfs.img
        echo "0 $( blockdev --getsize $BASE_LOOPDEV ) linear $BASE_LOOPDEV 0" | dmsetup create live-rw
    else
        # mount the filesystem read-only and add a dm snapshot for writes
        losetup -r $BASE_LOOPDEV $FSIMG
        do_live_from_base_loop
    fi
fi

[ -e "$SQUASHED" ] && umount -l /run/initramfs/squashfs

if [ -b "$OSMIN_LOOPDEV" ]; then
    # set up the devicemapper snapshot device, which will merge
    # the normal live fs image, and the delta, into a minimzied fs image
    echo "0 $( blockdev --getsz $BASE_LOOPDEV ) snapshot $BASE_LOOPDEV $OSMIN_LOOPDEV p 8" | dmsetup create --readonly live-osimg-min
fi

ROOTFLAGS="$(getarg rootflags)"
if [ -n "$ROOTFLAGS" ]; then
    ROOTFLAGS="-o $ROOTFLAGS"
fi

ln -s /dev/mapper/live-rw /dev/root
printf 'mount %s /dev/mapper/live-rw %s\n' "$ROOTFLAGS" "$NEWROOT" > $hookdir/mount/01-$$-live.sh

need_shutdown

exit 0
