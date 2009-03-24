
resume=$(getarg resume=) && ! getarg noresume && [ -b "$resume" ] && {
    # parsing the output of ls is Bad, but until there is a better way...
    (
    	echo -e 'KERNEL=="'${resume#/dev/}'", RUN+="/bin/sh -c \047 echo %M:%m > /sys/power/resume \047 "'
    	echo -e 'SYMLINK=="'${resume#/dev/}'", RUN+="/bin/sh -c \047 echo %M:%m > /sys/power/resume \047 "'
    ) >> /etc/udev/rules.d/99-resume.rules
}

(
 echo -e 'KERNEL=="'${root#/dev/}'", RUN+="/bin/sh -c \047 mount '$fstype' -o '$rflags' '$root' '$NEWROOT' \047 " '
 echo -e 'SYMLINK=="'${root#/dev/}'", RUN+="/bin/sh -c \047 mount '$fstype' -o '$rflags' '$root' '$NEWROOT' \047 " '
) >> /etc/udev/rules.d/99-mount.rules


