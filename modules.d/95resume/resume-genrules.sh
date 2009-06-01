resume=$(getarg resume=) && ! getarg noresume  && {
(
	/bin/echo -e 'KERNEL=="'${resume#/dev/}'", RUN+="/bin/echo %M:%m > /sys/power/resume"'
	/bin/echo -e 'SYMLINK=="'${resume#/dev/}'", RUN+="/bin/echo %M:%m > /sys/power/resume"'
) >> /etc/udev/rules.d/99-resume.rules
}
