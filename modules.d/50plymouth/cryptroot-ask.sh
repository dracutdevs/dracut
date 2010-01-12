#!/bin/sh

# do not ask, if we already have root
[ -f /sysroot/proc ] && exit 0

# check if destination already exists
[ -b /dev/mapper/$2 ] && exit 0

# we already asked for this device
[ -f /tmp/cryptroot-asked-$2 ] && exit 0

. /lib/dracut-lib.sh

# default luksname - luks-UUID
luksname=$2

# if device name is /dev/dm-X, convert to /dev/mapper/name
if [ "${1##/dev/dm-}" != "$1" ]; then
    device="/dev/mapper/$(dmsetup info -c --noheadings -o name "$1")"
else
    device="$1"
fi

if [ -f /etc/crypttab ] && ! getargs rd_NO_CRYPTTAB; then
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

LUKS=$(getargs rd_LUKS_UUID=)
ask=1
if [ -n "$LUKS" ]; then
    ask=0
    luuid=${2##luks-}
    for luks in $LUKS; do
	luks=${luks##luks-}
	if [ "${luuid##$luks}" != "$luuid" ] || [ "$luksname" = "$luks" ]; then
	    ask=1
	    break
	fi
    done
fi
unset LUKS luks luuid

if [ $ask -gt 0 ]; then
    info "luksOpen $device $luksname"
    # flock against other interactive activities
    { flock -s 9; 
	/bin/plymouth ask-for-password \
	    --prompt "$device ($luksname) is password protected" \
	    --command="/sbin/cryptsetup luksOpen -T1 $device $luksname"
    } 9>/.console.lock
fi
unset ask device luksname

# mark device as asked
>> /tmp/cryptroot-asked-$2

udevsettle

exit 0
# vim:ts=8:sw=4:sts=4:et