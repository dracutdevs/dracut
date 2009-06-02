if [ "$root" = "dhcp" ]; then
    if [ -n "$new_root_path" -a -z "${new_root_path%%iscsi:*}" ]; then
	root="$new_root_path"
    fi
fi

if [ -z "${root%iscsi:*}" ]; then
    handler=/sbin/iscsiroot
fi

if getarg iscsiroot >/dev/null; then
    handler=/sbin/iscsiroot
fi
