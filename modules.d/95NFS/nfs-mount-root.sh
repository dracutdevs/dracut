#!/bin/sh
set -x
if [ "$root" = "dhcp" ]; then 
    for dev in /net.*.dhcpopts; do 
	if [ -f "$dev" ]; then 
	    . "$dev"
	    [ -n "$new_root_path" ] && nfsroot="$new_root_path"
	    if [ ! -s /.resume -a "$nfsroot" ]; then
		if [ "${nfsroot#nfs://}" != "$nfsroot" ]; then
		    nfsroot="${nfsroot#nfs://}"
		    nfsroot="${nfsroot/\//:/}"
		fi
	    fi
	fi
    done
fi

if [ "${root#/dev/}" = "$root" -a "${root/:\///}" != "$root" ]; then
    nfsroot="$root"
fi


if [ -n "$nfsroot" ]; then
    #
    # modprobe nfs 
    #
    # start rpc.statd ??
    mount -t nfs "$nfsroot" -o nolock "$NEWROOT" && ROOTFS_MOUNTED=yes
fi
