if [ -n "$resume" ]; then
    [ -d /dev/.udev/rules.d ] || mkdir -p /dev/.udev/rules.d
    {
    printf "KERNEL==\"%s\", ACTION==\"add|change\", SYMLINK+=\"/dev/resume\"\n" \
		${resume#/dev/};
    printf "SYMLINK==\"%s\", ACTION==\"add|change\", SYMLINK+=\"/dev/resume\"\n" \
		${resume#/dev/};
    } >> /dev/.udev/rules.d/99-resume-link.rules

    {
    printf "KERNEL==\"%s\", ACTION==\"add|change\", ENV{ID_FS_TYPE}==\"suspend|swsuspend|swsupend\", RUN+=\"/bin/sh -c 'echo %%M:%%m > /sys/power/resume'\"\n" \
		${resume#/dev/};
    printf "SYMLINK==\"%s\", ACTION==\"add|change\", ENV{ID_FS_TYPE}==\"suspend|swsuspend|swsupend\", RUN+=\"/bin/sh -c 'echo %%M:%%m > /sys/power/resume'\"\n" \
		${resume#/dev/};
    } >> /etc/udev/rules.d/99-resume.rules

    printf '[ -e "%s" ] && { ln -s "%s" /dev/resume; rm "$job"; }\n' \
        "$resume" "$resume" >> /initqueue-settled/resume.sh

    echo '[ -e /dev/resume ]' > /initqueue-finished/resume.sh

elif  ! getarg noresume; then
    {
    echo "SUBSYSTEM==\"block\", ACTION==\"add|change\", ENV{ID_FS_TYPE}==\"suspend|swsuspend|swsupend\"," \
         " RUN+=\"/bin/sh -c 'echo %M:%m > /sys/power/resume'\"";
    } >> /etc/udev/rules.d/99-resume.rules
fi
