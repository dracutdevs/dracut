if [ "${root#/dev/}" != "$root" ]; then
    (
	echo 'KERNEL=="'${root#/dev/}'", RUN+="/bin/mount '$fstype' -o '$rflags' '$root' '$NEWROOT'" '
	echo 'SYMLINK=="'${root#/dev/}'", RUN+="/bin/mount '$fstype' -o '$rflags' '$root' '$NEWROOT'" '
    ) >> /etc/udev/rules.d/99-mount.rules
fi
