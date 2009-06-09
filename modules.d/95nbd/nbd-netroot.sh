if [ "$netroot" = "dhcp" ]; then
    if [ -n "$new_root_path" -a -z "${new_root_path%%nbd:*}" ]; then
	netroot="$new_root_path"
    fi
fi

if [ -z "${netroot%nbd:*}" ]; then
    handler=/sbin/nbdroot
fi
