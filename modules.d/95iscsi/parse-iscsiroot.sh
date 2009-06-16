#!/bin/sh
#
# Preferred format:
#	root=iscsi:[<servername>]:[<protocol>]:[<port>]:[<LUN>]:<targetname>
#	[root=*] netroot=iscsi:[<servername>]:[<protocol>]:[<port>]:[<LUN>]:<targetname>
#
# Legacy formats:
#	[net]root=[iscsi] iscsiroot=[<servername>]:[<protocol>]:[<port>]:[<LUN>]:<targetname>
# 	[net]root=[iscsi] iscsi_firmware
#
# root= takes precedence over netroot= if root=iscsi[...]
#

# Don't continue if root is ok
[ -n "$rootok" ] && return

# This script is sourced, so root should be set. But let's be paranoid
[ -z "$root" ] && root=$(getarg root=)
[ -z "$netroot" ] && netroot=$(getarg netroot=)
[ -z "$iscsiroot" ] && iscsiroot=$(getarg iscsiroot=)
[ -z "$iscsi_firmware" ] && getarg iscsi_firmware && iscsi_firmware="1"

[ -n "$iscsiroot" ] && [ -n "$iscsi_firmware" ] && die "Mixing iscsiroot and iscsi_firmware is dangerous"

# Root takes precedence over netroot
if [ "${root%%:*}" = "iscsi" ] ; then
    if [ -n "$netroot" ] ; then
	echo "Warning: root takes precedence over netroot. Ignoring netroot"

    fi
    netroot=$root
fi

# If it's not empty or iscsi we don't continue
[ -z "$netroot" ] || [ "${netroot%%:*}" = "iscsi" ] || return

if [ -n "$iscsiroot" ] ; then
    [ -z "$netroot" ]  && netroot=$root

    # @deprecated
    echo "Warning: Argument isciroot is deprecated and might be removed in a future"
    echo "release. See http://apps.sourceforge.net/trac/dracut/wiki/commandline for"
    echo "more information."

    # Accept iscsiroot argument?
    [ -z "$netroot" ] || [ "$netroot" = "iscsi" ] || \
	die "Argument iscsiroot only accepted for empty root= or [net]root=iscsi"

    # Override root with iscsiroot content?
    [ -z "$netroot" ] || [ "$netroot" = "iscsi" ] && netroot=iscsi:$iscsiroot
fi

# iscsi_firmware does not need argument checking
if [ -n "$iscsi_firmware" ] ; then
    netroot=${netroot:-iscsi}
fi

# If it's not iscsi we don't continue
[ "${netroot%%:*}" = "iscsi" ] || return

# Check required arguments. there's only one, but it's at the end
if [ -z "$iscsi_firmware" ] ; then
    case "${netroot##iscsi:*:*:*:*:}" in
	$netroot|'') die "Argument targetname for iscsiroot is missing";;
    esac
fi

# ISCSI actually supported?
[ -e /sys/devices/virtual/iscsi_transport ] || modprobe iscsi_tcp || die "iscsiroot requested but kernel/initrd does not support iscsi"

# Done, all good!
rootok=1

# Shut up init error check
[ -z "$root" ] && root="iscsi"
