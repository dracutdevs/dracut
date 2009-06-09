# We're 90-nfs.sh to catch root=/dev/nfs
#
# Preferred format:
#	root=nfs[4]:[server:]path[:options]
#	netroot=nfs[4]:[server:]path[:options]
#
# If server is unspecified it will be pulled from one of the following
# sources, in order:
#	static ip= option on kernel command line
#	DHCP next-server option
#	DHCP server-id option
#
# Legacy formats:
#	root=nfs[4]
#	root=/dev/nfs[4] nfsroot=[server:]path[,options]
#
# Plain "root=nfs" interprets DHCP root-path option as [ip:]path[:options]
#
# NFSv4 is only used if explicitly listed; default is NFSv3
#

case "$root" in
    nfs|dhcp|'')
	if getarg nfsroot= > /dev/null; then
	    root=nfs:$(getarg nfsroot=)
	fi
	;;
    nfs4)
	if getarg nfsroot= > /dev/null; then
	    root=nfs4:$(getarg nfsroot=)
	fi
	;;
    /dev/nfs|/dev/nfs4)
	if getarg nfsroot= > /dev/null; then
	    root=${root#/dev/}:$(getarg nfsroot=)
	else
	    root=${root#/dev/}
	fi
	;;
esac

if [ -z "$netroot" -a -n "$root" -a -z "${root%%nfs*}" ]; then
    netroot="$root"
    unset root
fi

case "$netroot" in
    nfs|nfs4|nfs:*|nfs4:*)
    	rootok=1
	if [ -n "$root" -a "$netroot" != "$root" ]; then
	    echo "WARNING: root= and netroot= do not match, ignoring root="
	fi
	unset root
    ;;
esac
