if [ -n "$resume" ]; then
    (
    printf "KERNEL==\"%s\", RUN+=\"/bin/sh -c 'echo %%M:%%m > /sys/power/resume'\"\n" \
		${resume#/dev/}
    printf "SYMLINK==\"%s\", RUN+=\"/bin/sh -c 'echo %%M:%%m > /sys/power/resume'\"\n" \
		${resume#/dev/}
    ) >> /etc/udev/rules.d/99-resume.rules
fi
