#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

. /lib/dracut-lib.sh

# Try to mount specified device (by path, by UUID or by label) and check
# the path with 'test'.
#
# example:
# test_dev -f LABEL="nice label" /some/file1
test_dev() {
    local test_op=$1; local dev="$2"; local f="$3"
    local ret=1; local mount_point=$(mkuniqdir /mnt testdev)
    local path

    [ -n "$dev" -a -n "$*" ] || return 1
    [ -d "$mount_point" ] || die 'Mount point does not exist!'

    if mount -r "$dev" "$mount_point" >/dev/null 2>&1; then
        test $test_op "${mount_point}/${f}"
        ret=$?
        umount "$mount_point"
    fi

    rmdir "$mount_point"

    return $ret
}

# Get kernel name for given device.  Device may be the name too (then the same
# is returned), a symlink (full path), UUID (prefixed with "UUID=") or label
# (prefixed with "LABEL=").  If just a beginning of the UUID is specified or
# even an empty, function prints all device names which UUIDs match - every in
# single line.
#
# NOTICE: The name starts with "/dev/".
#
# Example:
#   devnames UUID=123
# May print:
#   /dev/dm-1
#   /dev/sdb1
#   /dev/sdf3
devnames() {
    local dev="$1"; local d; local names

    case "$dev" in
    UUID=*)
        dev="$(foreach_uuid_until '! blkid -U $___' "${dev#UUID=}")" \
            && return 255
        [ -z "$dev" ] && return 255
        ;;
    LABEL=*) dev="$(blkid -L "${dev#LABEL=}")" || return 255 ;;
    /dev/?*) ;;
    *) return 255 ;;
    esac

    for d in $dev; do
        names="$names
$(readlink -e -q "$d")" || return 255
    done

    echo "${names#
}"
}

# match_dev devpattern dev
#
# Returns true if 'dev' matches 'devpattern'.  Both 'devpattern' and 'dev' are
# expanded to kernel names and then compared.  If name of 'dev' is on list of
# names of devices matching 'devpattern', the test is positive.  'dev' and
# 'devpattern' may be anything which function 'devnames' recognizes.
#
# If 'devpattern' is empty or '*' then function just returns true.
#
# Example:
#   match_dev UUID=123 /dev/dm-1
# Returns true if /dev/dm-1 UUID starts with "123".
match_dev() {
    [ -z "$1" -o "$1" = '*' ] && return 0
    local devlist; local dev

    devlist="$(devnames "$1")" || return 255
    dev="$(devnames "$2")" || return 255

    strstr "
$devlist
" "
$dev
"
}

# getkey keysfile for_dev
#
# Reads file <keysfile> produced by probe-keydev and looks for first line to
# which device <for_dev> matches.  The successful result is printed in format
# "<keydev>|<keypath>".  When nothing found, just false is returned.
#
# Example:
#   getkey /tmp/luks.keys /dev/sdb1
# May print:
#   /dev/sdc1|/keys/some.key
getkey() {
    local keys_file="$1"; local for_dev="$2"
    local luks_dev; local key_dev; local key_path

    [ -z "$keys_file" -o -z "$for_dev" ] && die 'getkey: wrong usage!'
    [ -f "$keys_file" ] || return 1

    while IFS='|' read luks_dev key_dev key_path; do
        if match_dev "$luks_dev" "$for_dev"; then
            echo "${key_dev}|${key_path}"
            return 0
        fi
    done < "$keys_file"

    return 1
}
