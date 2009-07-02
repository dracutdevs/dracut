#!/bin/sh

# do not ask, if we already have root
[ -f /sysroot/proc ] && exit 0

# check if destination already exists
[ -b /dev/mapper/$2 ] && exit 0

# we already asked for this device
[ -f /tmp/cryptroot-asked-$2 ] && exit 0

# flock against other interactive activities
{ flock -s 9; 
/bin/plymouth ask-for-password --prompt "$1 is password protected" --command="/sbin/cryptsetup luksOpen -T1 $1 $2"
} 9>/.console.lock

# mark device as asked
>> /tmp/cryptroot-asked-$2

exit 0

