#!/bin/sh # for highlighting

if [ "$root" = "dhcp" ]; then
    if [ -n "$new_root_path" -a -z "${new_root_path%%nbd:*}" ]; then
	root="$new_root_path"
    fi
fi

if [ -z "${root%nbd:*}" ]; then
    handler=/sbin/nbdroot
fi
