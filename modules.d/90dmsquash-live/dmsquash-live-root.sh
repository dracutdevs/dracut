#!/bin/sh

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
[ -z "$overlay_size" ] && overlay_size=32768

getargbool 0 rd.live.overlay.thin && thin_snapshot="yes"
getargbool 0 rd.live.overlay.overlayfs && overlayfs="yes"

# CD/DVD media check
[ -b $livedev ] && fs=$(blkid -s TYPE -o value $livedev)
if [ "$fs" = "iso9660" -o "$fs" = "udf" ]; then
    check="yes"
fi
getarg rd.live.check -d check || check=""
if [ -n "$check" ]; then
    type plymouth >/dev/null 2>&1 && plymouth --hide-splash
    if [ -n "$DRACUT_SYSTEMD" ]; then
        p=$(dev_unit_name "$livedev")
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
    udevadm settle >&2
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
        if [ -x "$(find_binary "ntfs-3g")" ]; then
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
    if [ -z "$setup" -a -n "$devspec" -a -n "$pathspec" -a -n "$overlay" ]; then
        mkdir -m 0755 /run/initramfs/overlayfs
        opt=''
        [ -n "$readonly_overlay" ] && opt=-r
        mount -n -t auto $devspec /run/initramfs/overlayfs || :
        if [ -f /run/initramfs/overlayfs$pathspec -a -w /run/initramfs/overlayfs$pathspec ]; then
            OVERLAY_LOOPDEV=$(losetup -f --show $opt /run/initramfs/overlayfs$pathspec)
            over=$OVERLAY_LOOPDEV
            umount -l /run/initramfs/overlayfs || :
            oltype=$(det_img_fs $OVERLAY_LOOPDEV)
            if [ -z "$oltype" ] || [ "$oltype" = DM_snapshot_cow ]; then
                if [ -n "$reset_overlay" ]; then
                    info "Resetting the Device-mapper overlay."
                    dd if=/dev/zero of=$OVERLAY_LOOPDEV bs=64k count=1 conv=fsync 2>/dev/null
                fi
                if [ -n "$overlayfs" ]; then
                    unset -v overlayfs
                    [ -n "$DRACUT_SYSTEMD" ] && reloadsysrootmountunit="yes"
                fi
                setup="yes"
            else
                mount -n -t $oltype $opt $OVERLAY_LOOPDEV /run/initramfs/overlayfs
                if [ -d /run/initramfs/overlayfs/overlayfs ] &&
                    [ -d /run/initramfs/overlayfs/ovlwork ]; then
                    ln -s /run/initramfs/overlayfs/overlayfs /run/overlayfs$opt
                    ln -s /run/initramfs/overlayfs/ovlwork /run/ovlwork$opt
                    if [ -z "$overlayfs" ]; then
                        overlayfs="yes"
                        [ -n "$DRACUT_SYSTEMD" ] && reloadsysrootmountunit="yes"
                    fi
                    setup="yes"
                fi
            fi
        elif [ -d /run/initramfs/overlayfs$pathspec ] &&
            [ -d /run/initramfs/overlayfs$pathspec/../ovlwork ]; then
            ln -s /run/initramfs/overlayfs$pathspec /run/overlayfs$opt
            ln -s /run/initramfs/overlayfs$pathspec/../ovlwork /run/ovlwork$opt
            if [ -z "$overlayfs" ]; then
                overlayfs="yes"
                [ -n "$DRACUT_SYSTEMD" ] && reloadsysrootmountunit="yes"
            fi
            setup="yes"
        fi
    fi
    if [ -n "$overlayfs" ]; then
        modprobe overlay
        if [ $? != 0 ]; then
            m='OverlayFS is not available; using temporary Device-mapper overlay.'
            unset -v overlayfs setup
            [ -n "$reloadsysrootmountunit" ] && unset -v reloadsysrootmountunit
        fi
    fi

    if [ -z "$setup" -o -n "$readonly_overlay" ]; then
        if [ -n "$setup" ]; then
            warn "Using temporary overlay."
        elif [ -n "$devspec" -a -n "$pathspec" ]; then
            [ -z "$m" ] &&
                m='  Unable to find a persistent overlay; using a temporary one.'
            m=($'\n' "$m" $'\n'
               '     All root filesystem changes will be lost on shutdown.'
               $'\n' '        Press any key to continue')
            echo -e "\n\n\n${m[*]}\n\n\n" > /dev/kmsg
            if [ -n "$DRACUT_SYSTEMD" ]; then
                if plymouth --ping ; then
                    if getargbool 0 rhgb || getargbool 0 splash ; then
                        m[0]='>>>'$'\n''>>>'$'\n''>>>'$'\n\n'
                        m[5]=$'\n''<<<'$'\n''<<<'$'\n''<<<'
                        plymouth display-message --text="${m[*]}"
                    else
                        plymouth ask-question --prompt="${m[*]}" --command=true
                    fi
                else
                    m[0]='>>>'
                    m[5]='<<<'
                    unset -v m[2] m[4]
                    systemd-ask-password --timeout=0 "${m[*]}"
                fi
            else
                plymouth --ping && plymouth --quit
                read -s -r -p $'\n\n'"${m[*]}:" -n 1 reply
            fi
        fi
        if [ -n "$overlayfs" ]; then
            mkdir -m 0755 /run/overlayfs
            mkdir -m 0755 /run/ovlwork
        else
            dd if=/dev/null of=/overlay bs=1024 count=1 seek=$((overlay_size*1024)) 2> /dev/null
            if [ -n "$setup" -a -n "$readonly_overlay" ]; then
                RO_OVERLAY_LOOPDEV=$(losetup -f --show /overlay)
                over=$RO_OVERLAY_LOOPDEV
            else
                OVERLAY_LOOPDEV=$(losetup -f --show /overlay)
                over=$OVERLAY_LOOPDEV
            fi
        fi
    fi

    # set up the snapshot
    if [ -z "$overlayfs" ]; then
        if [ -n "$readonly_overlay" ] && [ -n "$OVERLAY_LOOPDEV" ]; then
            echo 0 $sz snapshot $BASE_LOOPDEV $OVERLAY_LOOPDEV P 8 | dmsetup create --readonly live-ro
            base="/dev/mapper/live-ro"
        else
            base=$BASE_LOOPDEV
        fi
    fi

    if [ -n "$thin_snapshot" ]; then
        modprobe dm_thin_pool
        mkdir -m 0755 /run/initramfs/thin-overlay

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
    elif [ -z "$overlayfs" ]; then
        echo 0 $sz snapshot $base $over PO 8 | dmsetup create live-rw
    fi

    # Create a device that always points to a ro base image
    if [ -n "$overlayfs" ]; then
        BASE_LOOPDUP=$(losetup -f --show -r $BASE_LOOPDEV)
        echo 0 $sz linear $BASE_LOOPDUP 0 | dmsetup create --readonly live-base
    else
        echo 0 $sz linear $BASE_LOOPDEV 0 | dmsetup create --readonly live-base
    fi
}

# we might have a genMinInstDelta delta file for anaconda to take advantage of
if [ -e /run/initramfs/live/${live_dir}/osmin.img ]; then
    OSMINSQFS=/run/initramfs/live/${live_dir}/osmin.img
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
if [ -e "$SQUASHED" ]; then
    if [ -n "$live_ram" ]; then
        echo 'Copying live image to RAM...' > /dev/kmsg
        echo ' (this may take a minute)' > /dev/kmsg
        dd if=$SQUASHED of=/run/initramfs/squashed.img bs=512 2> /dev/null
        echo 'Done copying live image to RAM.' > /dev/kmsg
        SQUASHED="/run/initramfs/squashed.img"
    fi

    SQUASHED_LOOPDEV=$( losetup -f )
    losetup -r $SQUASHED_LOOPDEV $SQUASHED
    mkdir -m 0755 -p /run/initramfs/squashfs
    mount -n -t squashfs -o ro $SQUASHED_LOOPDEV /run/initramfs/squashfs

    if [ -f /run/initramfs/squashfs/LiveOS/rootfs.img ]; then
        FSIMG="/run/initramfs/squashfs/LiveOS/rootfs.img"
    elif [ -f /run/initramfs/squashfs/LiveOS/ext3fs.img ]; then
        FSIMG="/run/initramfs/squashfs/LiveOS/ext3fs.img"
    elif [ -d /run/initramfs/squashfs/usr ]; then
        FSIMG="$SQUASHED"
    fi
else
    # we might have an embedded fs image to use as rootfs (uncompressed live)
    if [ -e /run/initramfs/live/${live_dir}/rootfs.img ]; then
        FSIMG="/run/initramfs/live/${live_dir}/rootfs.img"
    elif [ -e /run/initramfs/live/${live_dir}/ext3fs.img ]; then
        FSIMG="/run/initramfs/live/${live_dir}/ext3fs.img"
    fi
    if [ -n "$live_ram" ]; then
        echo 'Copying live image to RAM...' > /dev/kmsg
        echo ' (this may take a minute or so)' > /dev/kmsg
        dd if=$FSIMG of=/run/initramfs/rootfs.img bs=512 2> /dev/null
        echo 'Done copying live image to RAM.' > /dev/kmsg
        FSIMG='/run/initramfs/rootfs.img'
    fi
fi

if [ -n "$FSIMG" ] ; then
    if [ -n "$writable_fsimg" ] ; then
        # mount the provided filesystem read/write
        echo "Unpacking live filesystem (may take some time)" > /dev/kmsg
        mkdir -m 0755 /run/initramfs/fsimg/
        if [ -n "$SQUASHED" ]; then
            cp -v $FSIMG /run/initramfs/fsimg/rootfs.img
        else
            unpack_archive $FSIMG /run/initramfs/fsimg/
        fi
        FSIMG=/run/initramfs/fsimg/rootfs.img
    fi
    opt=-r
       # For writable DM images...
    if [ -z "$SQUASHED" -a -n "$live_ram" -a -z "$overlayfs" ] ||
       [ -n "$writable_fsimg" ] ||
       [ "$overlay" = none -o "$overlay" = None -o "$overlay" = NONE ]; then
        if [ -z "$readonly_overlay" ]; then
            opt=''
            setup=rw
        else
            setup=yes
        fi
    fi
    BASE_LOOPDEV=$(losetup -f --show $opt $FSIMG)
    sz=$(blockdev --getsz $BASE_LOOPDEV)
    if [ "$setup" == rw ]; then
        echo 0 $sz linear $BASE_LOOPDEV 0 | dmsetup create live-rw
    else
        # Add a DM snapshot or OverlayFS for writes.
        do_live_overlay
    fi
fi

[ -e "$SQUASHED" ] && [ -z "$overlayfs" ] && umount -l /run/initramfs/squashfs

if [ -b "$OSMIN_LOOPDEV" ]; then
    # set up the devicemapper snapshot device, which will merge
    # the normal live fs image, and the delta, into a minimzied fs image
    echo "0 $sz snapshot $BASE_LOOPDEV $OSMIN_LOOPDEV P 8" | dmsetup create --readonly live-osimg-min
fi

if [ -n "$reloadsysrootmountunit" ]; then
    > /xor_overlayfs
    systemctl daemon-reload
fi

ROOTFLAGS="$(getarg rootflags)"

if [ -n "$overlayfs" ]; then
    mkdir -m 0755 /run/rootfsbase
    if [ -n "$reset_overlay" ] && [ -L /run/overlayfs ]; then
        ovlfs=$(readlink /run/overlayfs)
        info "Resetting the OverlayFS overlay directory."
        rm -r -- ${ovlfs}/* ${ovlfs}/.* >/dev/null 2>&1
    fi
    if [ -n "$readonly_overlay" ]; then
        mkdir -m 0755 /run/rootfsbase-r
        mount -r $FSIMG /run/rootfsbase-r
        mount -t overlay LiveOS_rootfs-r -oro,lowerdir=/run/overlayfs-r:/run/rootfsbase-r /run/rootfsbase
    else
        mount -r $FSIMG /run/rootfsbase
    fi
    if [ -z "$DRACUT_SYSTEMD" ]; then
        #FIXME What to link to /dev/root? Is it even needed?
        printf 'mount -t overlay LiveOS_rootfs -o%s,%s %s\n' "$ROOTFLAGS" \
        'lowerdir=/run/rootfsbase,upperdir=/run/overlayfs,workdir=/run/ovlwork' \
        "$NEWROOT" > $hookdir/mount/01-$$-live.sh
    fi
else
    ln -s /dev/mapper/live-rw /dev/root
    if [ -z "$DRACUT_SYSTEMD" ]; then
        [ -n "$ROOTFLAGS" ] && ROOTFLAGS="-o $ROOTFLAGS"
        printf 'mount %s /dev/mapper/live-rw %s\n' "$ROOTFLAGS" "$NEWROOT" > $hookdir/mount/01-$$-live.sh
    fi
    ln -s $BASE_LOOPDEV /run/rootfsbase
fi

need_shutdown

exit 0
