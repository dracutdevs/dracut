#!/bin/bash # for highlighting

if [ "${root%%:*}" = "block" ]; then
    (
    printf 'KERNEL=="%s", RUN+="/bin/mount -t %s -o %s %s %s"\n' \
	${root#block:/dev/} "$fstype" "$rflags" "${root#block:}" "$NEWROOT"
    printf 'SYMLINK=="%s", RUN+="/bin/mount -t %s -o %s %s %s"\n' \
	${root#block:/dev/} "$fstype" "$rflags" "${root#block:}" "$NEWROOT"
    ) >> /etc/udev/rules.d/99-mount.rules
fi
