#!/bin/sh

type getarg > /dev/null 2>&1 || . /lib/dracut-lib.sh

if getargbool 0 rd.live.debug -n -y rdlivedebug; then
    exec > /run/initramfs/create-overlay.$$.out 2>&1
    set -x
    export RD_DEBUG=yes
    if [ "$BASH" ]; then
        export \
            PS4='+ (${BASH_SOURCE}@${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
    else
        export PS4='+ (${0##*/}@${LINENO}): '
    fi
fi

runParted() {
    LC_ALL=C flock "$1" parted --script "$@"
}

getPartitionName() {
    # Return an appropriate name for partition $2. Devices that end with a
    # digit need to have a 'p' prepended to the partition number.
    local dev="$1"
    local pn="${2:-1}"
    [ "$pn" -lt 1 ] && pn=1

    case "${dev}~" in
        *dm-[0-9]~)
            local ppath=/devices/virtual/block/"${dev##*/}"
            dev=/dev/mapper/$(cat /sys"$ppath"/dm/name)
            ;;
    esac
    case "${dev}~" in
        *[0-9]~)
            printf '%s' "${dev}p$pn"
            ;;
        *)
            printf '%s' "${dev}$pn"
            ;;
    esac
}

trim_var() {
    # Trim variable $1 to length $2.
    printf '%.*s' "$2" "$1"
}

mkfs_config() {
    local fstype="${1:=ext4}"
    local lbl="$2"
    local sz="$3"
    ops=''
    case "$fstype" in
        btrfs)
            # mkfs.btrfs maximum label length is 255 characters.
            _label=$(trim_var "$lbl" 255)
            ops="-f -L $_label"
            # Recommended for out of space problems on filesystems under 16 GiB.
            # https://btrfs.wiki.kernel.org/index.php/FAQ#if_your_device_is_small
            [ "$sz" -lt $((1 << 34)) ] && ops="${ops} --mixed"
            ;;
        ext[432])
            case "$fstype" in
                ext[43]) ops='-j' ;;
            esac
            # mkfs.ext[432] maximum label length is 16 bytes.
            _label=$(trim_var "$lbl" 16)
            ops="${ops:+"${ops} "}-F -L $_label"
            # Recommended for filesystems under 512 MiB.
            # https://manned.org/mkfs.ext4.8
            [ "$sz" -lt $((1 << 29)) ] && ops="${ops} -T small"
            ;;
        f2fs)
            # mkfs.f2fs maximum label length is 512 unicode characters.
            _label=$(trim_var "$lbl" 512)
            ops="-f -l $_label -O sb_checksum"
            ;;
        xfs)
            # mkfs.xfs maximum label length is 12 characters.
            _label=$(trim_var "$lbl" 12)
            ops="-f -L $_label"
            ;;
    esac
    mkfs=mkfs.$fstype
}

gatherData() {
    if ! autooverlay=$(getarg rd.live.autooverlay); then
        info "Skipping overlay creation: kernel command line parameter 'rd.live.autooverlay' is not set."
        exit 0
    fi
    # shellcheck disable=SC2086
    [ -b "$autooverlay" ] || autooverlay=$(label_uuid_to_dev "$autooverlay")
    if [ -b "$autooverlay" ]; then
        info "Skipping overlay creation: overlay already exists."
        exit 0
    fi

    fstype=$(getarg rd.live.autooverlay.cowfs) || fstype=ext4
    case "$fstype" in
        btrfs | ext[432] | f2fs | xfs) : ;;
        *)
            die "Overlay creation failed: only filesystems btrfs|ext[432]|f2fs|xfs are supported in the 'rd.live.autooverlay.cowfs' kernel parameter"
            ;;
    esac

    live_dir=$(getarg rd.live.dir -d live_dir) || live_dir=LiveOS

    [ "$1" ] || exit 1
    rootDevice=$1

    # The kernel command line's 'root=' parameter was parsed into the $root variable by the dmsquash-live module.
    # $root contains the path to a symlink within /dev/disk/by-XXXXXXXX, which points to a partition.
    # This script needs that partition's parent block device.
    rootDeviceAbsolutePath=$(readlink -nf "${rootDevice}")
    # shellcheck disable=SC2086
    rootDeviceSysfsPath=$(readlink -nf /sys/class/block/${rootDeviceAbsolutePath##*/})
    if [ -f "${rootDeviceSysfsPath}/partition" ]; then
        # shellcheck disable=SC2086
        read -r partition < ${rootDeviceSysfsPath}/partition
    else
        partition=0
    fi
    # shellcheck disable=SC2086
    read -r readonly < ${rootDeviceSysfsPath}/ro
    if [ "$partition" != "1" ] || [ "$readonly" != "0" ]; then
        info "Skipping overlay creation: unpartitioned or read-only media detected."
        exit 0
    fi
    if [ "$partition" ]; then
        # shellcheck disable=SC2086
        fullDriveSysfsPath=$(readlink -nf ${rootDeviceSysfsPath}/..)
    else
        fullDriveSysfsPath=${rootDeviceSysfsPath}
    fi
    # shellcheck disable=SC2086
    blockDevice=${fullDriveSysfsPath##*/}

    IFS='
'
    # shellcheck disable=SC2046
    set -- $(runParted /dev/"${blockDevice}" --fix -m unit B print free)
    currentPartitionCount=$(eval echo \$"$(($# - 1))")
    currentPartitionCount=${currentPartitionCount%%:*}
    IFS=' :'
    # shellcheck disable=SC2046
    set -- $(eval echo \$"$#")
    IFS=' 	
'
    freeSpaceStart=${2%B}
    freeSpaceEnd=${3%B}
    freeSpaceAvailable=${4%B}
    if [ "$freeSpaceAvailable" -lt $((1 << 27)) ]; then
        # if available space is less that 128 MiB.
        info "Skipping overlay creation: there is insufficient free space after the last partition."
        exit 0
    fi

    udevadm settle >&2
    IFS=' '
    # shellcheck disable=SC2046
    set -- $(lsblk -nrdbo LABEL,UUID,OPT-IO "${rootDeviceAbsolutePath}")
    label=$1
    uuid=$2
    if [ ! "$label" ] || [ ! "$uuid" ]; then
        die "Overlay creation failed: failed to look up root device label and UUID."
    fi

    optimalIO=$3
    # make optimalIO alignment at least 4 MiB
    # See https://www.gnu.org/software/parted/manual/parted.html#FOOT2
    [ "$optimalIO" -le 512 ] && optimalIO=$((1 << 22))

    if [ "$((freeSpaceStart % optimalIO))" -gt 0 ]; then
        partitionStart=$(((freeSpaceStart / optimalIO + 1) * optimalIO))
    else
        partitionStart=${freeSpaceStart}
    fi
    freeSpaceAvailable=$((freeSpaceEnd - partitionStart))

    overlayPartition=$(getPartitionName /dev/"${blockDevice}" $((currentPartitionCount + 1)))
}

createPartition() {
    printf 'Making partition %s_persist as %s.\n' "${live_dir}" "${overlayPartition}" > /dev/kmsg
    runParted /dev/"${blockDevice}" --align optimal mkpart "${live_dir}"_persist "${partitionStart}B" 100%
}

createFilesystem() {
    mkfs_config "$fstype" "${live_dir}"_persist $freeSpaceAvailable
    printf "Making %s filesystem on %s.\n" "$fstype" "${overlayPartition}" > /dev/kmsg
    # shellcheck disable=SC2086
    LC_ALL=C flock /dev/"${blockDevice}" "${mkfs}" ${ops} "${overlayPartition}"

    baseDir=/run/initramfs/create-overlayfs
    mkdir -p ${baseDir}
    mount -t auto "${overlayPartition}" ${baseDir}

    mkdir -p "${baseDir}/${live_dir}"/ovlwork
    mkdir "${baseDir}/${live_dir}/overlay-${label}-${uuid}"
    setfattr -n security.selinux -v system_u:object_r:root_t:s0 \
        "${baseDir}/${live_dir}/overlay-${label}-${uuid}" \
        "${baseDir}/${live_dir}"/ovlwork

    umount ${baseDir}
    rm -r ${baseDir}
}

main() {
    gatherData "$1"
    createPartition
    udevadm settle >&2
    createFilesystem
    udevadm settle >&2
}

main "$1"
