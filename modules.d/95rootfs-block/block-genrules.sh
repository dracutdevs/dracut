if [ "${root%%:*}" = "block" ]; then
    (
    printf 'KERNEL=="%s", SYMLINK+="root"\n' \
	${root#block:/dev/} 
    printf 'SYMLINK=="%s", SYMLINK+="root"\n' \
	${root#block:/dev/} 
    ) >> /etc/udev/rules.d/99-mount.rules
fi
