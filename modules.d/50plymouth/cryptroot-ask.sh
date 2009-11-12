#!/bin/sh

# do not ask, if we already have root
[ -f /sysroot/proc ] && exit 0

# check if destination already exists
[ -b /dev/mapper/$2 ] && exit 0

# we already asked for this device
[ -f /tmp/cryptroot-asked-$2 ] && exit 0

. /lib/dracut-lib.sh

luksname=$2

if [ -f /etc/crypttab ] && ! getargs rd_NO_CRYPTTAB; then
    found=0
    while read name dev rest; do
        cdev=$(readlink -f $dev)
        mdev=$(readlink -f $1)
        if [ "$cdev" = "$mdev" ]; then
            # for now just ignore everything which is in crypttab
            # anaconda does not write an entry for root
            exit 0
            #luksname="$name"
            #break
    fi
    done < /etc/crypttab
fi

LUKS=$(getargs rd_LUKS_UUID=)
ask=1

if [ -n "$LUKS" ]; then
    ask=0
    luuid=${2##luks-}
    for luks in $LUKS; do
	luks=${luks##luks-}
	if [ "${luuid##$luks}" != "$luuid" ] || [ "$luksname" == "$luks" ]; then
	    ask=1
	    break
	fi
    done
fi

if [ $ask -gt 0 ]; then
    info "luksOpen $1 $2"
    # flock against other interactive activities
    { flock -s 9; 
	/bin/plymouth ask-for-password \
	    --prompt "$1 is password protected" \
	    --command="/sbin/cryptsetup luksOpen -T1 $1 $luksname"
    } 9>/.console.lock
fi

# mark device as asked
>> /tmp/cryptroot-asked-$2

udevsettle

unset LUKS
unset ask
unset luks
exit 0
# vim:ts=8:sw=4:sts=4:et

