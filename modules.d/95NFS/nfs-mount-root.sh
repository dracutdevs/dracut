#!/bin/sh
set -x

for dev in /net.*.dhcpopts; do 
    if [ -f "$dev" ]; then 
	. "$dev"
	[ -n "$new_root_path" ] && nfsroot="$new_root_path"
	if [ ! -s /.resume -a "$nfsroot" ]; then
	    if [ "${nfsroot#nfs://}" != "$nfsroot" ]; then
		nfsroot="${nfsroot#nfs://}"
		nfsroot="${nfsroot/\//:/}"
		#
		#modprobe nfs
		#
		# start rpc.statd ??
		mount -t nfs "$nfsroot" -o nolock "$NEWROOT" && ROOTFS_MOUNTED=yes
	    fi
	fi
    fi
done

