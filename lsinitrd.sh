#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
#
# Copyright 2005-2010 Harald Hoyer <harald@redhat.com>
# Copyright 2005-2010 Red Hat, Inc.  All rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

usage()
{
    echo "Usage: $(basename $0) [-s] [<initramfs file> [<filename>]]"
}

[[ $# -le 2 ]] || { usage ; exit 1 ; }

sorted=0
while getopts "s" opt; do
    case $opt in
        s)  sorted=1;;
        h)  usage; exit 0;;
        \?) usage; exit 1;;
    esac
done
shift $((OPTIND-1))

image="${1:-/boot/initramfs-$(uname -r).img}"
[[ -f "$image" ]]    || { echo "$image does not exist" ; exit 1 ; }

CAT=zcat
FILE_T=$(file --dereference "$image")

if echo "test"|xz|xz -dc --single-stream >/dev/null 2>&1; then
    XZ_SINGLE_STREAM="--single-stream"
fi

if [[ "$FILE_T" =~ :\ gzip\ compressed\ data ]]; then
    CAT=zcat
elif [[ "$FILE_T" =~ :\ xz\ compressed\ data ]]; then
    CAT="xzcat $XZ_SINGLE_STREAM"
elif [[ "$FILE_T" =~ :\ XZ\ compressed\ data ]]; then
    CAT="xzcat $XZ_SINGLE_STREAM"
elif [[ "$FILE_T" =~ :\ LZMA ]]; then
    CAT="xzcat $XZ_SINGLE_STREAM"
elif [[ "$FILE_T" =~ :\ data ]]; then
    CAT="xzcat $XZ_SINGLE_STREAM"
fi

if [[ $# -eq 2 ]]; then
    $CAT $image | cpio --extract --verbose --quiet --to-stdout ${2#/} 2>/dev/null
    exit $?
fi

echo "$image: $(du -h $image | awk '{print $1}')"
echo "========================================================================"
$CAT "$image" | cpio --extract --verbose --quiet --to-stdout 'lib/dracut/dracut-*' 2>/dev/null
echo "========================================================================"
if [ "$sorted" -eq 1 ]; then
    $CAT "$image" | cpio --extract --verbose --quiet --list | sort -n -k5
else
    $CAT "$image" | cpio --extract --verbose --quiet --list
fi
echo "========================================================================"
