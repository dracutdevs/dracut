if [ "${root%%:*}" = "live" ]; then
    (
    printf 'KERNEL=="%s", SYMLINK+="live"\n' \
    	${root#live:/dev/} 
    printf 'SYMLINK=="%s", SYMLINK+="live"\n' \
	${root#live:/dev/} 
    printf 'KERNEL=="%s", RUN+="/sbin/initqueue --settled --onetime --unique /sbin/dmsquash-live-root $env{DEVNAME}"\n' \
    	${root#live:/dev/} 
    printf 'SYMLINK=="%s", RUN+="/sbin/initqueue --settled --onetime --unique /sbin/dmsquash-live-root $env{DEVNAME}"\n' \
	${root#live:/dev/} 

    ) >> /etc/udev/rules.d/99-live-mount.rules
    echo '[ -e /dev/root ]' > /initqueue-finished/dmsquash.sh
fi
