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
    {
        echo "Usage: ${0##*/} [options] [<initramfs file> [<filename> [<filename> [...] ]]]"
        echo "Usage: ${0##*/} [options] -k <kernel version>"
        echo
        echo "-h, --help                  print a help message and exit."
        echo "-s, --size                  sort the contents of the initramfs by size."
        echo "-m, --mod                   list modules."
        echo "-f, --file <filename>       print the contents of <filename>."
        echo "-k, --kver <kernel version> inspect the initramfs of <kernel version>."
        echo
    } >&2
}


[[ $dracutbasedir ]] || dracutbasedir=/usr/lib/dracut

sorted=0
modules=0
declare -A filenames

unset POSIXLY_CORRECT
TEMP=$(getopt \
    -o "shmf:k:" \
    --long kver: \
    --long file: \
    --long mod \
    --long help \
    --long size \
    -- "$@")

if (( $? != 0 )); then
    usage
    exit 1
fi

eval set -- "$TEMP"

while (($# > 0)); do
    case $1 in
        -k|--kver)  KERNEL_VERSION="$2"; shift;;
        -f|--file)  filenames[${2#/}]=1; shift;;
        -s|--size)  sorted=1;;
        -h|--help)  usage; exit 0;;
        -m|--mod)   modules=1;;
        --)         shift;break;;
        *)          usage; exit 1;;
    esac
    shift
done

[[ $KERNEL_VERSION ]] || KERNEL_VERSION="$(uname -r)"

if [[ $1 ]]; then
    image="$1"
    if ! [[ -f "$image" ]]; then
        {
            echo "$image does not exist"
            echo
        } >&2
        usage
        exit 1
    fi
else
    [[ -f /etc/machine-id ]] && read MACHINE_ID < /etc/machine-id

    if [[ -d /boot/loader/entries || -L /boot/loader/entries ]] \
        && [[ $MACHINE_ID ]] \
        && [[ -d /boot/${MACHINE_ID} || -L /boot/${MACHINE_ID} ]] ; then
        image="/boot/${MACHINE_ID}/${KERNEL_VERSION}/initrd"
    else
        image="/boot/initramfs-${KERNEL_VERSION}.img"
    fi
fi

shift
while (($# > 0)); do
    filenames[${1#/}]=1;
    shift
done

if ! [[ -f "$image" ]]; then
    {
        echo "No <initramfs file> specified and the default image '$image' cannot be accessed!"
        echo
    } >&2
    usage
    exit 1
fi

extract_files()
{
    (( ${#filenames[@]} == 1 )) && nofileinfo=1
    for f in "${!filenames[@]}"; do
        [[ $nofileinfo ]] || echo "initramfs:/$f"
        [[ $nofileinfo ]] || echo "========================================================================"
        $CAT $image 2>/dev/null | cpio --extract --verbose --quiet --to-stdout $f 2>/dev/null
        ((ret+=$?))
        [[ $nofileinfo ]] || echo "========================================================================"
        [[ $nofileinfo ]] || echo
    done
}

list_modules()
{
    echo "dracut modules:"
    $CAT "$image" 2>/dev/null | cpio --extract --verbose --quiet --to-stdout -- 'lib/dracut/modules.txt' 'usr/lib/dracut/modules.txt' 2>/dev/null
    ((ret+=$?))
}

list_files()
{
    echo "========================================================================"
    if [ "$sorted" -eq 1 ]; then
        $CAT "$image" 2>/dev/null | cpio --extract --verbose --quiet --list | sort -n -k5
    else
        $CAT "$image" 2>/dev/null | cpio --extract --verbose --quiet --list | sort -k9
    fi
    ((ret+=$?))
    echo "========================================================================"
}


if (( ${#filenames[@]} <= 0 )); then
    echo "Image: $image: $(du -h $image | while read a b; do echo $a;done)"
    echo "========================================================================"
fi

read -N 6 bin < "$image"
case $bin in
    $'\x71\xc7'*|070701)
        CAT="cat --"
        is_early=$(cpio --extract --verbose --quiet --to-stdout -- 'early_cpio' < "$image" 2>/dev/null)
        if [[ "$is_early" ]]; then
            if (( ${#filenames[@]} > 0 )); then
                extract_files
            else
                echo "Early CPIO image"
                list_files
            fi
            SKIP="$dracutbasedir/skipcpio"
            if ! [[ -x $SKIP ]]; then
                echo
                echo "'$SKIP' not found, cannot display remaining contents!" >&2
                echo
                exit 0
            fi
        fi
        ;;
esac

if [[ $SKIP ]] ; then
    bin="$($SKIP "$image" | { read -N 6 bin && echo "$bin" ; })"
else
    read -N 6 bin < "$image"
fi
case $bin in
    $'\x1f\x8b'*)
        CAT="zcat --"
        ;;
    BZh*)
        CAT="bzcat --"
        ;;
    $'\x71\xc7'*|070701)
        CAT="cat --"
        ;;
    $'\x02\x21'*)
        CAT="lz4 -d -c"
        ;;
    $'\x89'LZO$'\0'*)
        CAT="lzop -d -c"
        ;;
    *)
        if echo "test"|xz|xzcat --single-stream >/dev/null 2>&1; then
            CAT="xzcat --single-stream --"
        else
            CAT="xzcat --"
        fi
        ;;
esac

skipcpio()
{
    $SKIP "$@" | $ORIG_CAT
}

if [[ $SKIP ]]; then
    ORIG_CAT="$CAT"
    CAT=skipcpio
fi

ret=0

if (( ${#filenames[@]} > 0 )); then
    extract_files
else
    version=$($CAT "$image" 2>/dev/null | cpio --extract --verbose --quiet --to-stdout -- 'lib/dracut/dracut-*' 'usr/lib/dracut/dracut-*' 2>/dev/null)
    ((ret+=$?))
    echo "Version: $version"
    echo
    if [ "$modules" -eq 1 ]; then
        list_modules
        echo "========================================================================"
    else
        echo -n "Arguments: "
        $CAT "$image" 2>/dev/null | cpio --extract --verbose --quiet --to-stdout -- 'lib/dracut/build-parameter.txt' 'usr/lib/dracut/build-parameter.txt' 2>/dev/null
        echo
        list_modules
        list_files
    fi
fi

exit $ret
