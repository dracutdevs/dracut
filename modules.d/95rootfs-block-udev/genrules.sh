
resume=$(getarg resume=) && ! getarg noresume && [ -b "$resume" ] && {
    (
    	/bin/echo -e 'KERNEL=="'${resume#/dev/}'", RUN+="/bin/echo %M:%m > /sys/power/resume"'
    	/bin/echo -e 'SYMLINK=="'${resume#/dev/}'", RUN+="/bin/echo %M:%m > /sys/power/resume"'
    ) >> /etc/udev/rules.d/99-resume.rules
}

(
 echo 'KERNEL=="'${root#/dev/}'", RUN+="/bin/mount '$fstype' -o '$rflags' '$root' '$NEWROOT'" '
 echo 'SYMLINK=="'${root#/dev/}'", RUN+="/bin/mount '$fstype' -o '$rflags' '$root' '$NEWROOT'" '
) >> /etc/udev/rules.d/99-mount.rules


