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

# fallback to passphrase
ask_passphrase=1

# if device name is /dev/dm-X, convert to /dev/mapper/name
if [ "${1##/dev/dm-}" != "$1" ]; then
    device="/dev/mapper/$(dmsetup info -c --noheadings -o name "$1")"
else
    device="$1"
fi

# number of tries
numtries=${3:-10}

# TODO: improve to support what cmdline does
if [ -f /etc/crypttab ] && getargbool 1 rd.luks.crypttab -d -n rd_NO_CRYPTTAB; then
    while read name dev luksfile luksoptions; do
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
    unset name dev
fi

#
# Open LUKS device
#

info "luksOpen $device $luksname $luksfile $luksoptions"

OLD_IFS="$IFS"
IFS=,
set -- $luksoptions
IFS="$OLD_IFS"

while [ $# -gt 0 ]; do
    case $1 in
        noauto)
            # skip this
            exit 0
            ;;
        swap)
            # skip this
            exit 0
            ;;
        tmp)
            # skip this
            exit 0
            ;;
        allow-discards)
            allowdiscards="--allow-discards"
    esac
    shift
done

# parse for allow-discards
if strstr "$(cryptsetup --help)" "allow-discards"; then
    if discarduuids=$(getargs "rd.luks.allow-discards"); then
        discarduuids=$(str_replace "$discarduuids" 'luks-' '')
        if strstr " $discarduuids " " ${luksdev##luks-}"; then
            allowdiscards="--allow-discards"
        fi
    elif getargbool 0 rd.luks.allow-discards; then
        allowdiscards="--allow-discards"
    fi
fi

if strstr "$(cryptsetup --help)" "allow-discards"; then
    cryptsetupopts="$cryptsetupopts $allowdiscards"
fi

unset allowdiscards

if [ -n "$luksfile" -a "$luksfile" != "none" -a -e "$luksfile" ]; then
    if cryptsetup --key-file "$luksfile" $cryptsetupopts luksOpen "$device" "$luksname"; then
        ask_passphrase=0
    fi
else
    while [ -n "$(getarg rd.luks.key)" ]; do
        if tmp=$(getkey /tmp/luks.keys $device); then
            keydev="${tmp%%:*}"
            keypath="${tmp#*:}"
        else
            if [ $numtries -eq 0 ]; then
                warn "No key found for $device.  Fallback to passphrase mode."
                break
            fi
            sleep 1
            info "No key found for $device.  Will try $numtries time(s) more later."
            initqueue --unique --onetime --settled \
                --name cryptroot-ask-$luksname \
                $(command -v cryptroot-ask) "$device" "$luksname" "$(($numtries-1))"
            exit 0
        fi
        unset tmp

        info "Using '$keypath' on '$keydev'"
        readkey "$keypath" "$keydev" "$device" \
            | cryptsetup -d - $cryptsetupopts luksOpen "$device" "$luksname"
        unset keypath keydev
        ask_passphrase=0
        break
    done
fi

if [ $ask_passphrase -ne 0 ]; then
    luks_open="$(command -v cryptsetup) $cryptsetupopts luksOpen"
    ask_for_password --ply-tries 5 \
        --ply-cmd "$luks_open -T1 $device $luksname" \
        --ply-prompt "Password ($device)" \
        --tty-tries 1 \
        --tty-cmd "$luks_open -T5 $device $luksname"
    unset luks_open
fi

unset device luksname luksfile

# mark device as asked
>> /tmp/cryptroot-asked-$2

need_shutdown
udevsettle

exit 0
