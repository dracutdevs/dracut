#!/bin/sh

case "${root#block:}" in
    LABEL=* | UUID=* | PARTUUID=* | PARTLABEL=*)
        root="block:$(label_uuid_to_dev "$root")"
        rootok=1
        ;;
    /dev/*)
        root="block:${root#block:}"
        # shellcheck disable=SC2034
        rootok=1
        ;;
esac

[ "${root%%:*}" = "block" ] && wait_for_dev "${root#block:}"
