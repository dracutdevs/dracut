# If we're auto-detecting our root type from DHCP, see if this looks like
# an NFS root option. As the variety of root-path formats is large, validate
# that the number of colons match what we expect, and our glob didn't
# inadvertently match a different handler's.
#
if [ "$netroot" = "dhcp" -o "$netroot" = "nfs" -o "$netroot" = "nfs4" ]; then
    nfsver=nfs
    if [ "$netroot" = "nfs4" ]; then
	nfsver=nfs4
    fi
    case "$new_root_path" in
    nfs:*|nfs4:*) netroot="$new_root_path" ;;
    *:/*:*)
	if check_occurances "$new_root_path" ':' 2; then
	    netroot="$nfsver:$new_root_path"
	fi ;;
    *:/*,*)
	if check_occurances "$new_root_path" ':' 1; then
	    netroot="$nfsver:$new_root_path"
	fi ;;
    *:/*)
	if check_occurances "$new_root_path" ':' 1; then
	    netroot="$nfsver:$new_root_path:"
	fi ;;
    /*:*)
	if check_occurances "$new_root_path" ':' 1; then
	    netroot="$nfsver::$new_root_path"
	fi ;;
    /*,*)
	if check_occurances "$new_root_path" ':' 0; then
	    netroot="$nfsver::$new_root_path"
	fi ;;
    /*)
	if check_occurances "$new_root_path" ':' 0; then
	    netroot="$nfsver::$new_root_path:"
	fi ;;
    '') netroot="$nfsver:::" ;;
    esac
fi

if [ -z "${netroot%%nfs:*}" -o -z "${netroot%%nfs4:*}" ]; then
    # Fill in missing information from DHCP
    nfsver=${netroot%%:*}; netroot=${netroot#*:}
    nfsserver=${netroot%%:*}; netroot=${netroot#*:}
    nfspath=${netroot%%:*}
    nfsflags=${netroot#*:}

    # XXX where does dhclient stash the next-server option? Do we care?
    if [ -z "$nfsserver" -o "$nfsserver" = "$nfspath" ]; then
	nfsserver=$new_dhcp_server_identifier
    fi

    # Handle alternate syntax of path,options
    if [ "$nfsflags" = "$nfspath" -a "${netroot#*,}" != "$netroot" ]; then
	nfspath=${netroot%%,*}
	nfsflags=${netroot#*,}
    fi

    # Catch the case when no additional flags are set
    if [ "$nfspath" = "$nfsflags" ]; then
	unset nfsflags
    fi

    # XXX validate we have all the required info?
    netroot="$nfsver:$nfsserver:$nfspath:$nfsflags"
    handler=/sbin/nfsroot
fi
