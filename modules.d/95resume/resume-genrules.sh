if [ -n "$resume" ]; then
    (
    printf 'KERNEL=="%s", RUN+="/bin/echo %%M:%%m > /sys/power/resume"\n' \
		${resume#/dev/}
    printf 'SYMLINK=="%s", RUN+="/bin/echo %%M:%%m > /sys/power/resume"\n' \
		${resume#/dev/}
    ) >> /etc/udev/rules.d/99-resume.rules
fi
