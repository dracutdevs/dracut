# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

if [ -n "$resume" ]; then
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

elif ! getarg noresume; then
    {
        echo "SUBSYSTEM==\"block\", ACTION==\"add|change\", ENV{ID_FS_TYPE}==\"suspend|swsuspend|swsupend\"," \
            " RUN+=\"/bin/sh -c 'echo %M:%m > /sys/power/resume'\"";
    } >> /etc/udev/rules.d/99-resume.rules
fi
