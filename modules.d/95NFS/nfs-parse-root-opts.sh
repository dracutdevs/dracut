#!/bin/sh

# exit if rootfstype is set and not nfs
if [ -z "$fstype" -o "$fstype" = "nfs" ]; then
    if [ "$root" = "dhcp" ]; then 
	for dev in /net.*.dhcpopts; do 
	    if [ -f "$dev" ]; then 
		. "$dev"
		[ -n "$new_root_path" ] && nfsroot="$new_root_path"
		if [ ! -s /.resume -a -n "$nfsroot" ]; then
		    if [ "${nfsroot#nfs://}" != "$nfsroot" ]; then
			nfsroot="${nfsroot#nfs://}"
			nfsroot="${nfsroot/\//:/}"
		    fi
		    break
		fi
	    fi
	done
    elif [ "${root#/dev/}" = "$root" -a "${root#*:/}" != "$root" ]; then
	nfsroot="$root"
    fi

    # let user force override nfsroot
    nfsroot_cmdl=$(getarg 'nfsroot=') 
    [ -n "$nfsroot_cmdl" ] && nfsroot="$nfsroot_cmdl"

    if [ -n "$nfsroot" ]; then
	root="$nfsroot" 
	fstype="-t nfs"
	
	if rflags="$(getarg rootflags=)"; then
	    getarg rw && rflags="${rflags},rw" || rflags="${rflags},ro"
	else
	    getarg rw && rflags=rw || rflags=ro
	fi

	rflags="nolock,$rflags"
    fi
fi
