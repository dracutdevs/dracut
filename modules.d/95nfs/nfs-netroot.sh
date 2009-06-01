# If we're auto-detecting our root type from DHCP, see if this looks like
# an NFS root option. As the variety of root-path formats is large, validate
# that the number of colons match what we expect, and our glob didn't
# inadvertently match a different handler's.
#
if [ "$root" = "dhcp" -o "$root" = "nfs" -o "$root" = "nfs4" ]; then
    nfsver=nfs
    if [ "$root" = "nfs4" ]; then
	nfsver=nfs4
    fi
    case "$new_root_path" in
    nfs:*|nfs4:*) root="$new_root_path" ;;
    *:/*:*)
	if check_occurances "$new_root_path" ':' 2; then
	    root="$nfsver:$new_root_path"
	fi ;;
    *:/*)
	if check_occurances "$new_root_path" ':' 1; then
	    root="$nfsver:$new_root_path:"
	fi ;;
    /*:*)
	if check_occurances "$new_root_path" ':' 1; then
	    root="$nfsver::$new_root_path"
	fi ;;
    /*)
	if check_occurances "$new_root_path" ':' 0; then
	    root="$nfsver::$new_root_path:"
	fi ;;
    esac
fi

if [ -z "${root%%nfs:*}" -o -z "${root%%nfs4:*}" ]; then
    # Fill in missing information from DHCP
    nfsver=${root%%:*}; root=${root#*:}
    nfsserver=${root%%:*}; root=${root#*:}
    nfspath=${root%%:*}
    nfsflags=${root#*:}

    # XXX where does dhclient stash the next-server option? Do we care?
    if [ -z "$nfsserver" -o "$nfsserver" = "$nfspath" ]; then
	nfsserver=$new_dhcp_server_identifier
    fi
    if [ "$nfspath" = "$nfsflags" ]; then
	unset nfsflags
    fi

    # XXX validate we have all the required info?
    root="$nfsver:$nfsserver:$nfspath:$nfsflags"
    handler=/sbin/nfsroot
fi
