#!/bin/sh
#
# Preferred format:
#	root=nfs[4]:[server:]path[:options]
#	[root=*] netroot=nfs[4]:[server:]path[:options]
#
# Legacy formats:
#	[net]root=[[/dev/]nfs[4]] nfsroot=[server:]path[,options]
#	[net]root=[[/dev/]nfs[4]] nfsroot=[server:]path[:options]
#
# If the 'nfsroot' parameter is not given on the command line or is empty,
# the dhcp root-path is used as [server:]path[:options] or the default
# "/tftpboot/%s" will be used.
#
# If server is unspecified it will be pulled from one of the following
# sources, in order:
#	static ip= option on kernel command line
#	DHCP next-server option
#	DHCP server-id option
#       DHCP root-path option
#
# NFSv4 is only used if explicitly requested; default is NFSv2 or NFSv3
# depending on kernel configuration
#
# root= takes precedence over netroot= if root=nfs[...]
#

# Sadly there's no easy way to split ':' separated lines into variables
netroot_to_var() {
    local v=${1}:
    set --
    while [ -n "$v" ]; do
	set -- "$@" "${v%%:*}"
	v=${v#*:}
    done

    unset nfs server path options

    nfs=$1
    # Ugly: Can't -z test #path after the case, since it might be allowed
    # to be empty for root=nfs
    case $# in
    0|1);;
    2)	path=${2:-error};;
    3)
    # This is ultra ugly. But we can't decide in which position path
    # sits without checking if the string starts with '/'
    case $2 in
	/*) path=$2; options=$3;;
	*) server=$2; path=${3:-error};;
    esac
    ;;
    *)	server=$2; path=${3:-error}; options=$4;
    esac
    
    # Does it really start with '/'?
    [ -n "${path%%/*}" ] && path="error";
    
    #Fix kernel legacy style separating path and options with ','
    if [ "$path" != "${path#*,}" ] ; then
	options=${path#*,}
	path=${path%%,*}
    fi
}

#Don't continue if root is ok
[ -n "$rootok" ] && return

# This script is sourced, so root should be set. But let's be paranoid
[ -z "$root" ] && root=$(getarg root=)
[ -z "$netroot" ] && netroot=$(getarg netroot=)
[ -z "$nfsroot" ] && nfsroot=$(getarg nfsroot=)

# Root takes precedence over netroot
case "${root%%:*}" in
    nfs|nfs4|/dev/nfs|/dev/nfs4)
    if [ -n "$netroot" ] ; then
	warn "root takes precedence over netroot. Ignoring netroot"

    fi
    netroot=$root
    ;;
esac

# If it's not empty or nfs we don't continue
case "${netroot%%:*}" in
    ''|nfs|nfs4|/dev/nfs|/dev/nfs4);;
    *) return;;
esac

if [ -n "$nfsroot" ] ; then
    [ -z "$netroot" ]  && netroot=$root

    # @deprecated
    warn "Argument nfsroot is deprecated and might be removed in a future release. See http://apps.sourceforge.net/trac/dracut/wiki/commandline for more information."

    case "$netroot" in
	''|nfs|nfs4|/dev/nfs|/dev/nfs4) netroot=${netroot:-nfs}:$nfsroot;;
	*) die "Argument nfsroot only accepted for empty root= or root=[/dev/]nfs[4]"
    esac
fi

# If it's not nfs we don't continue
case "${netroot%%:*}" in
    nfs|nfs4|/dev/nfs|/dev/nfs4);;
    *) return;;
esac

# Check required arguments
netroot_to_var $netroot
[ "$path" = "error" ] && die "Argument nfsroot must contain a valid path!"

# Set fstype, might help somewhere
fstype=${nfs#/dev/}

# NFS actually supported? Some more uglyness here: nfs3 or nfs4 might not
# be in the module...
if ! incol2 /proc/filesystems $fstype ; then
    modprobe nfs
    incol2 /proc/filesystems $fstype || die "nfsroot type $fstype requested but kernel/initrd does not support nfs"
fi

# Rewrite root so we don't have to parse this uglyness later on again
netroot="$fstype:$server:$path:$options"

# If we don't have a server, we need dhcp
if [ -z "$server" ] ; then
    DHCPORSERVER="1"
fi;

# Done, all good!
rootok=1

# Shut up init error check or make sure that block parser wont get 
# confused by having /dev/nfs[4]
root="$fstype"
