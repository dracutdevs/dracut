#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
#
# root=aufs:<mountpoint>:<rwbranch>:<robranch>[,<options>]
#

type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh
. /lib/aufs-lib.sh

#Don't continue if root is ok
[ -n "$rootok" ] && return

# This script is sourced, so root should be set. But let's be paranoid
[ -z "$root" ] && root=$(getarg root=)

# If it's not aufs we don't continue
[ "${root%%:*}" = "aufs" ] || return

# Check required arguments
aufs_to_var $root

[ -n "$aufsrwbranch" ] || die "Argument aufsroot needs r/w branch"
[ -n "$aufsrobranch" ] || die "Argument aufsroot needs r/o branch"

# Load module
modprobe aufs

# Create mountpoints
mkdir "${aufsrwbranch}" "${aufsrobranch}"

# Done, all good!
rootok=1
