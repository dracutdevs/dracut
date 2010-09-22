#!/bin/sh
fstab_mount(){
    local dev mp type opts rest
    test -e "$1" || return 1
    info "Mounting from $1"
    while read dev mp type opts rest; do
	[ -z "${dev%%#*}" ]&& continue # Skip comment lines
	mount -v -t $type -o $opts $dev $NEWROOT/$mp
    done < $1 | vinfo
    return 0
}

for r in $NEWROOT /; do
    fstab_mount "$r/etc/fstab.sys" && break
done
