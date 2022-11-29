#!/bin/sh

type getarg > /dev/null 2>&1 || . /lib/dracut-lib.sh

if getargbool 0 rd.live.debug -n -y rdlivedebug; then
    exec > /tmp/create-overlay.$$.out
    exec 2>> /tmp/create-overlay.$$.out
    set -x
fi

gatherData() {
    overlay=$(getarg rd.live.overlay)
    if [ -z "$overlay" ]; then
        info "Skipping overlay creation: kernel command line parameter 'rd.live.overlay' is not set"
        exit 0
    fi
    # shellcheck disable=SC2086
    if ! str_starts ${overlay} LABEL=; then
        die "Overlay creation failed: the partition must be set by LABEL in the 'rd.live.overlay' kernel parameter"
    fi

    overlayLabel=${overlay#LABEL=}
    # shellcheck disable=SC2086
    if [ -b /dev/disk/by-label/${overlayLabel} ]; then
        info "Skipping overlay creation: overlay already exists"
        exit 0
    fi

    filesystem=$(getarg rd.live.overlay.cowfs)
    [ -z "$filesystem" ] && filesystem="ext4"
    if [ "$filesystem" != "ext4" ] && [ "$filesystem" != "xfs" ] && [ "$filesystem" != "btrfs" ]; then
        die "Overlay creation failed: only ext4, xfs, and btrfs are supported in the 'rd.live.overlay.cowfs' kernel parameter"
    fi

    live_dir=$(getarg rd.live.dir)
    [ -z "$live_dir" ] && live_dir="LiveOS"

    [ -z "$1" ] && exit 1
    rootDevice=$1

    # The kernel command line's 'root=' parameter was parsed into the $root variable by the dmsquash-live module.
    # $root contains the path to a symlink within /dev/disk/by-label, which points to a partition.
    # This script needs that partition's parent block device.
    # shellcheck disable=SC2046
    # shellcheck disable=SC2086
    rootDeviceAbsolutePath=$(readlink -f ${rootDevice})
    rootDeviceSysfsPath=/sys/class/block/${rootDeviceAbsolutePath##*/}
    if [ -f "${rootDeviceSysfsPath}/partition" ]; then
        # shellcheck disable=SC2086
        read -r partition < ${rootDeviceSysfsPath}/partition
    else
        partition=0
    fi
    # shellcheck disable=SC2086
    read -r readonly < ${rootDeviceSysfsPath}/ro
    # shellcheck disable=SC2086
    if [ "$partition" != "1" ] || [ "$readonly" != "0" ]; then
        info "Skipping overlay creation: unpartitioned or read-only media detected"
        exit 0
    fi
    # shellcheck disable=SC2046
    # shellcheck disable=SC2086
    fullDriveSysfsPath=$(readlink -f ${rootDeviceSysfsPath}/..)
    blockDevice=/dev/${fullDriveSysfsPath##*/}
    currentPartitionCount=$(grep --count -E "${blockDevice#/dev/}[0-9]+" /proc/partitions)

    # shellcheck disable=SC2086
    freeSpaceStart=$(parted --script ${blockDevice} unit % print free \
        | awk -v x=${currentPartitionCount} '$1 == x {getline; print $1}')
    if [ -z "$freeSpaceStart" ]; then
        info "Skipping overlay creation: there is no free space after the last partition"
        exit 0
    fi
    partitionStart=$((${freeSpaceStart%.*} + 1))
    if [ $partitionStart -eq 100 ]; then
        info "Skipping overlay creation: there is not enough free space after the last partition"
        exit 0
    fi

    overlayPartition=${blockDevice}$((currentPartitionCount + 1))

    label=$(blkid --match-tag LABEL --output value "$rootDevice")
    uuid=$(blkid --match-tag UUID --output value "$rootDevice")
    if [ -z "$label" ] || [ -z "$uuid" ]; then
        die "Overlay creation failed: failed to look up root device label and UUID"
    fi
}

createPartition() {
    # shellcheck disable=SC2086
    parted --script --align optimal ${blockDevice} mkpart primary ${partitionStart}% 100%
}

createFilesystem() {
    # shellcheck disable=SC2086
    mkfs.${filesystem} -L ${overlayLabel} ${overlayPartition}

    baseDir=/run/initramfs/create-overlayfs
    mkdir -p ${baseDir}
    # shellcheck disable=SC2086
    mount -t auto ${overlayPartition} ${baseDir}

    mkdir -p ${baseDir}/${live_dir}/ovlwork
    # shellcheck disable=SC2086
    mkdir ${baseDir}/${live_dir}/overlay-${label}-${uuid}

    umount ${baseDir}
    rm -r ${baseDir}
}

main() {
    gatherData "$1"
    createPartition
    udevsettle
    createFilesystem
    udevsettle
}

main "$1"
