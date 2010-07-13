#!/bin/sh

# do not ask, if we already have root
[ -f /sysroot/proc ] && exit 0

# check if destination already exists
[ -b /dev/mapper/$2 ] && exit 0

# we already asked for this device
[ -f /tmp/cryptroot-asked-$2 ] && exit 0

# load dm_crypt if it is not already loaded
[ -d /sys/module/dm_crypt ] || modprobe dm_crypt

. /lib/dracut-lib.sh

# default luksname - luks-UUID
luksname=$2

# if device name is /dev/dm-X, convert to /dev/mapper/name
if [ "${1##/dev/dm-}" != "$1" ]; then
    device="/dev/mapper/$(dmsetup info -c --noheadings -o name "$1")"
else
    device="$1"
fi

if [ -f /etc/crypttab ] && ! getarg rd_NO_CRYPTTAB; then
    while read name dev rest; do
        # ignore blank lines and comments
        if [ -z "$name" -o "${name#\#}" != "$name" ]; then
            continue
        fi

        # UUID used in crypttab
        if [ "${dev%%=*}" = "UUID" ]; then
            if [ "luks-${dev##UUID=}" = "$2" ]; then
                luksname="$name"
                break
            fi
        
        # path used in crypttab
        else
            cdev=$(readlink -f $dev)
            mdev=$(readlink -f $device)
            if [ "$cdev" = "$mdev" ]; then
                luksname="$name"
                break
            fi
        fi
    done < /etc/crypttab
    unset name dev rest
fi

#
# Search key on external devices
#

# Try to mount device specified by UUID and probe for existence of any of
# the paths.  On success return 0 and print "<uuid> <first-existing-path>",
# otherwise return 1.
# Function leaves mount point created.
probe_keydev() {
    local uuid="$1"; shift; local keypaths="$*"
    local ret=1; local mount_point=/mnt/keydev
    local path

    [ -n "${uuid}" -a -n "${keypaths}" ] || return 1
    [ -d ${mount_point} ] || mkdir -p "${mount_point}" || return 1

    if mount -r -U "${uuid}" "${mount_point}" 2>/dev/null >/dev/null; then
        for path in ${keypaths}; do
            if [ -f "${mount_point}/${path}" ]; then
                echo "${uuid} ${path}"
                ret=0
                break
            fi
        done
    fi

    umount "${mount_point}" 2>/dev/null >/dev/null

    return ${ret}
}

keypaths="$(getargs rd_LUKS_KEYPATH)"
unset keydev_uuid keypath

if [ -n "$keypaths" ]; then
    keydev_uuids="$(getargs rd_LUKS_KEYDEV_UUID)"
    [ -n "$keydev_uuids" ] || {
            warn 'No UUID of device storing LUKS key specified.'
            warn 'It is recommended to set rd_LUKS_KEYDEV_UUID.'
            warn 'Performing scan of *all* devices accessible by UUID...'
    }
    tmp=$(foreach_uuid_until "probe_keydev \$full_uuid $keypaths" \
            $keydev_uuids) && {
        keydev_uuid="${tmp%% *}"
        keypath="${tmp#* }"
    } || {
        warn "Key for $device not found."
    }
    unset tmp keydev_uuids
fi

unset keypaths

#
# Open LUKS device
#

info "luksOpen $device $luksname"

if [ -n "$keydev_uuid" ]; then
    mntp=/mnt/keydev
    mkdir -p "$mntp"
    mount -r -U "$keydev_uuid" "$mntp"
    cryptsetup -d "$mntp/$keypath" luksOpen "$device" "$luksname"
    umount "$mntp"
    rmdir -p "$mntp" 2>/dev/null
else
    # flock against other interactive activities
    { flock -s 9;
        echo -n "$device ($luksname) is password protected"
        cryptsetup luksOpen -T1 $1 $luksname
    } 9>/.console.lock
fi

# mark device as asked
>> /tmp/cryptroot-asked-$2

exit 0
# vim:ts=8:sw=4:sts=4:et
