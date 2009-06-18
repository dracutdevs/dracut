if [ -n "$resume" ]; then
    (
    printf "KERNEL==\"%s\", RUN+=\"/bin/sh -c 'echo %%M:%%m > /sys/power/resume'\"\n" \
		${resume#/dev/}
    printf "SYMLINK==\"%s\", RUN+=\"/bin/sh -c 'echo %%M:%%m > /sys/power/resume'\"\n" \
		${resume#/dev/}
    ) >> /etc/udev/rules.d/99-resume.rules
elif  ! getarg noresume; then
    echo "SUBSYSTEM==\"block\", ACTION==\"add\", ENV{ID_FS_TYPE}==\"suspend\", RUN+=\"/bin/sh -c 'echo %M:%m > /sys/power/resume'\"" \
    >> /etc/udev/rules.d/99-resume.rules
fi
