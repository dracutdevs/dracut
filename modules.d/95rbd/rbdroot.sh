#!/bin/sh

type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh
. /lib/rbd-lib.sh

PATH=/usr/sbin:/usr/bin:/sbin:/bin

# Huh? Empty $1?
[ -z "$1" ] && exit 1

# Huh? Empty $2?
[ -z "$2" ] && exit 1

# Huh? Empty $3?
[ -z "$3" ] && exit 1

# root is in the form root=rbd:<mon>[+<mon2>+<mon3>]:<user>:<key>:<pool>:<image>[@<snapshot>]:[<part>]:[<mntopts>]
netif="$1"
rbdroot="$2"
NEWROOT="$3"

# If it's not rbd we don't continue
[ "${rbdroot%%:*}" = "rbd" ] || return

rbdroot=${rbdroot#rbd:}
parse_rbdroot "$rbdroot"

# XXX: separate option for fstype?
fstype=auto

# append ro/rw to fs mount options if needed
getarg ro && roflag=ro
getarg rw && roflag=rw
# fallback to ro whether roflag is not set
[ -z "$roflag" ] && roflag=ro
opts=${opts:+$opts,}$roflag

# the kernel will reject writes to add if add_single_major exists
if [ -e /sys/bus/rbd/add_single_major ]; then
    rbd_bus=/sys/bus/rbd/add_single_major
elif [ -e /sys/bus/rbd/add ]; then
    rbd_bus=/sys/bus/rbd/add
else
    echo "ERROR: /sys/bus/rbd/add does not exist"
    return 1
fi

# tell the kernel rbd client to map the block device
echo "$mons name=$user,secret=$key $pool $image $snap" > $rbd_bus
# figure out where the block device appeared
dev=$(ls /dev/rbd* | grep '/dev/rbd[0-9]*$' | tail -n 1)
# add partition if set
if [ $partition ]; then
    dev=${dev}p$partition
fi

mount -t $fstype $dev $NEWROOT -o $opts

# force udevsettle to break
> $hookdir/initqueue/work
