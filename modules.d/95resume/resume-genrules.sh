if [ -n "$resume" ]; then
    {
    printf "KERNEL==\"%s\", RUN+=\"/bin/sh -c 'echo %%M:%%m > /sys/power/resume'\"\n" \
		${resume#/dev/};
    printf "SYMLINK==\"%s\", RUN+=\"/bin/sh -c 'echo %%M:%%m > /sys/power/resume'\"\n" \
		${resume#/dev/};
    } >> /etc/udev/rules.d/99-resume.rules

    printf '[ -e "%s" ] && { ln -s "%s" /dev/resume; rm "$job"; }\n' \
        "$resume" "$resume" >> /initqueue-settled/resume.sh

    echo '[ -e /dev/resume ]' > /initqueue-finished/resume.sh

elif  ! getarg noresume; then
    {
    echo "SUBSYSTEM==\"block\", ACTION==\"add\", ENV{ID_FS_TYPE}==\"suspend\"," \
         " RUN+=\"/bin/sh -c 'echo %M:%m > /sys/power/resume'\"";
    echo "SUBSYSTEM==\"block\", ACTION==\"add\", ENV{ID_FS_TYPE}==\"swsuspend\"," \
         " RUN+=\"/bin/sh -c 'echo %M:%m > /sys/power/resume'\"";
    } >> /etc/udev/rules.d/99-resume.rules
fi
