if [ "${root%%:*}" = "block" ]; then
    (
    printf 'KERNEL=="%s", RUN+="/sbin/initqueue /bin/mount -t %s -o %s %s %s"\n' \
	${root#block:/dev/} "$fstype" "$rflags" "${root#block:}" "$NEWROOT"
    printf 'SYMLINK=="%s", RUN+="/sbin/initqueue /bin/mount -t %s -o %s %s %s"\n' \
	${root#block:/dev/} "$fstype" "$rflags" "${root#block:}" "$NEWROOT"
    ) >> /etc/udev/rules.d/99-mount.rules
fi
