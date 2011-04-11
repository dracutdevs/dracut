#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

PATH=/usr/sbin:/usr/bin:/sbin:/bin
NEWROOT=${NEWROOT:-"/sysroot"}

# do not ask, if we already have root
[ -f $NEWROOT/proc ] && exit 0

# check if destination already exists
[ -b /dev/mapper/$2 ] && exit 0

# we already asked for this device
[ -f /tmp/cryptroot-asked-$2 ] && exit 0

# load dm_crypt if it is not already loaded
[ -d /sys/module/dm_crypt ] || modprobe dm_crypt

. /lib/dracut-crypt-lib.sh

# default luksname - luks-UUID
luksname=$2

# if device name is /dev/dm-X, convert to /dev/mapper/name
if [ "${1##/dev/dm-}" != "$1" ]; then
    device="/dev/mapper/$(dmsetup info -c --noheadings -o name "$1")"
else
    device="$1"
fi

# TODO: improve to support what cmdline does
if [ -f /etc/crypttab ] && getargbool 1 rd.luks.crypttab -n rd_NO_CRYPTTAB; then
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
# Open LUKS device
#

info "luksOpen $device $luksname"

if [ -n "$(getarg rd.luks.key)" ]; then
    if tmp=$(getkey /tmp/luks.keys $device); then
        keydev="${tmp%%:*}"
        keypath="${tmp#*:}"
    else
        info "No key found for $device.  Will try later."
        initqueue --unique --onetime --settled \
            --name cryptroot-ask-$luksname \
            $(command -v cryptroot-ask) "$@"
        exit 0
    fi
    unset tmp

    mntp=$(mkuniqdir /mnt keydev)
    mount -r "$keydev" "$mntp" || die 'Mounting rem. dev. failed!'
    cryptsetup -d "$mntp/$keypath" luksOpen "$device" "$luksname"
    umount "$mntp"
    rmdir "$mntp"
    unset mntp keypath keydev
else
    # Prompt for password with plymouth, if installed and running.
    if [ -x /bin/plymouth ] && /bin/plymouth --has-active-vt; then
        prompt="Password [$device ($luksname)]:" 
        if [ ${#luksname} -gt 8 ]; then
            sluksname=${sluksname##luks-}
            sluksname=${luksname%%${luksname##????????}}
            prompt="Password for $device ($sluksname...)"
        fi
        
        # flock against other interactive activities
        { flock -s 9; 
            /bin/plymouth ask-for-password \
                --prompt "$prompt" --number-of-tries=5 \
                --command="$(command -v cryptsetup) luksOpen -T1 $device $luksname"
        } 9>/.console.lock
        
        unset sluksname prompt
        
    else
        # flock against other interactive activities
        { flock -s 9;
            echo "$device ($luksname) is password protected"
            cryptsetup luksOpen -T5 $device $luksname
        } 9>/.console.lock
    fi
fi

unset device luksname

# mark device as asked
>> /tmp/cryptroot-asked-$2

udevsettle

exit 0
