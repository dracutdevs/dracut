#!/bin/sh
# img-lib.sh: utilities for dealing with archives and filesystem images.
#
# TODO: identify/unpack rpm, deb, maybe others?

# super-simple "file" that only identifies archives.
# works with stdin if $1 is not set.
det_archive() {
    # NOTE: internal echo -e works in ash and bash, but not dash
    local bz xz gz zs
    local headerblock
    bz="BZh"
    # shellcheck disable=SC3037
    xz="$(/bin/echo -e '\xfd7zXZ')"
    # shellcheck disable=SC3037
    gz="$(/bin/echo -e '\x1f\x8b')"
    # shellcheck disable=SC3037
    zs="$(/bin/echo -e '\x28\xB5\x2F\xFD')"
    headerblock="$(dd ${1:+if=$1} bs=262 count=1 2> /dev/null | tr -d '\0')"
    case "$headerblock" in
        $xz*) echo "xz" ;;
        $gz*) echo "gzip" ;;
        $bz*) echo "bzip2" ;;
        $zs*) echo "zstd" ;;
        07070*) echo "cpio" ;;
        *ustar) echo "tar" ;;
    esac
}

# determine filesystem type for a filesystem image
det_fs_img() {
    local dev
    dev=$(losetup --find --show "$1") rv=""
    det_fs "$dev"
    rv=$?
    losetup -d "$dev"
    return $rv
}

# unpack_archive ARCHIVE OUTDIR
# unpack a (possibly compressed) cpio/tar archive
unpack_archive() {
    local img="$1" outdir="$2" archiver="" decompr=""
    local ft
    ft="$(det_archive "$img")"
    case "$ft" in
        xz | gzip | bzip2 | zstd) decompr="$ft -dc" ;;
        cpio | tar) decompr="cat" ;;
        *) return 1 ;;
    esac
    ft="$($decompr "$img" | det_archive)"
    case "$ft" in
        cpio) archiver="cpio -iumd" ;;
        tar) archiver="tar -xf -" ;;
        *) return 2 ;;
    esac
    mkdir -p "$outdir"
    (
        cd "$outdir" || exit
        $decompr | $archiver 2> /dev/null
    ) < "$img"
}

# unpack_fs FSIMAGE OUTDIR
# unpack a filesystem image
unpack_fs() {
    local img="$1" outdir="$2"
    local mnt
    mnt="$(mkuniqdir /tmp unpack_fs.)"
    mount -o loop "$img" "$mnt" || {
        rmdir "$mnt"
        return 1
    }
    mkdir -p "$outdir"
    outdir="$(
        cd "$outdir" || exit
        pwd
    )"
    copytree "$mnt" "$outdir"
    umount "$mnt"
    rmdir "$mnt"
}

# unpack an image file - compressed/uncompressed cpio/tar, filesystem, whatever
# unpack_img IMAGEFILE OUTDIR
unpack_img() {
    local img="$1" outdir="$2"
    [ -r "$img" ] || {
        warn "can't read img!"
        return 1
    }
    [ -n "$outdir" ] || {
        warn "unpack_img: no output dir given"
        return 1
    }

    if [ "$(det_archive "$img")" ]; then
        unpack_archive "$@" || {
            warn "can't unpack archive file!"
            return 1
        }
    else
        unpack_fs "$@" || {
            warn "can't unpack filesystem image!"
            return 1
        }
    fi
}

# parameter: <size of live image> in MiB
# Call emergency shell if ram size is too small for the image.
# Increase /run tmpfs size, if needed.
check_live_ram() {
    local minmem imgsize memsize runsize runavail
    minmem=$(getarg rd.minmem)
    imgsize=$1
    memsize=$(($(check_meminfo MemTotal:) >> 10))
    # shellcheck disable=SC2046
    set -- $(findmnt -bnro SIZE,AVAIL /run)
    # bytes to MiB
    runsize=$(($1 >> 20))
    runavail=$(($2 >> 20))

    [ "$imgsize" ] || {
        warn "Image size could not be determined"
        return 0
    }

    if [ $((memsize - imgsize)) -lt "${minmem:=1024}" ]; then
        sed -i "N;/and attach it to a bug report./s/echo$/echo\n\
         echo \n\
         echo 'Warning!!!'\n\
         echo 'The memory size of your system is too small for this live image.'\n\
         echo 'Expect killed processes due to out of memory conditions.'\n\
         echo \n/" /usr/bin/dracut-emergency

        emergency_shell
    elif [ $((runavail - imgsize)) -lt "$minmem" ]; then
        # Increase /run tmpfs size, if needed.
        mount -o remount,size=$((runsize - runavail + imgsize + minmem))M /run
    fi
}
