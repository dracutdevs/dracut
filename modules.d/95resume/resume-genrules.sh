#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

case "$splash" in
    quiet )
        a_splash="-P splash=y"
    ;;
    * )
        a_splash="-P splash=n"
    ;;
esac

if [ -n "$resume" ]; then
    {
        printf "KERNEL==\"%s\", ACTION==\"add|change\", SYMLINK+=\"/dev/resume\"\n" \
            ${resume#/dev/};
        printf "SYMLINK==\"%s\", ACTION==\"add|change\", SYMLINK+=\"/dev/resume\"\n" \
            ${resume#/dev/};
    } >> /etc/udev/rules.d/99-resume-link.rules

    {
        if [ -x /usr/sbin/resume ]; then
            printf "KERNEL==\"%s\", ACTION==\"add|change\", ENV{ID_FS_TYPE}==\"suspend|swsuspend|swsupend\", RUN+=\"/sbin/initqueue --finished --unique --name 00resume /usr/sbin/resume %s \'%s\'\"\n" \
                ${resume#/dev/} "$a_splash" "$resume";
            printf "SYMLINK==\"%s\", ACTION==\"add|change\", ENV{ID_FS_TYPE}==\"suspend|swsuspend|swsupend\", RUN+=\"/sbin/initqueue --finished --unique --name 00resume /usr/sbin/resume %s \'%s\'\"\n" \
                ${resume#/dev/} "$a_splash" "$resume";
        fi
        printf "KERNEL==\"%s\", ACTION==\"add|change\", ENV{ID_FS_TYPE}==\"suspend|swsuspend|swsupend\", RUN+=\"/sbin/initqueue --finished --unique --name 00resume echo %%M:%%m > /sys/power/resume\"\n" \
            ${resume#/dev/};
        printf "SYMLINK==\"%s\", ACTION==\"add|change\", ENV{ID_FS_TYPE}==\"suspend|swsuspend|swsupend\", RUN+=\"/sbin/initqueue --finished --unique --name 00resume echo %%M:%%m  > /sys/power/resume\"\n" \
            ${resume#/dev/};
    } >> /etc/udev/rules.d/99-resume.rules

    printf '[ -e "%s" ] && { ln -s "%s" /dev/resume; rm "$job" "%s/initqueue/timeout/resume.sh"; }\n' \
        "$resume" "$resume" "$hookdir" >> $hookdir/initqueue/settled/resume.sh

    printf 'warn "Cancelling resume operation. Device not found."; cancel_wait_for_dev /dev/resume; rm "$job" "%s/initqueue/settled/resume.sh";' \
        "$hookdir" >> $hookdir/initqueue/timeout/resume.sh

    wait_for_dev "/dev/resume"

elif ! getarg noresume; then
    {
        if [ -x /usr/sbin/resume ]; then
            printf "SUBSYSTEM==\"block\", ACTION==\"add|change\", ENV{ID_FS_TYPE}==\"suspend|swsuspend|swsupend\", RUN+=\"/sbin/initqueue --finished --unique --name 00resume /usr/sbin/resume %s \$tempnode\"\n" "$a_splash"
        fi
        echo "SUBSYSTEM==\"block\", ACTION==\"add|change\", ENV{ID_FS_TYPE}==\"suspend|swsuspend|swsupend\"," \
            " RUN+=\"/sbin/initqueue --finished --unique --name 00resume echo %M:%m > /sys/power/resume\"";
    } >> /etc/udev/rules.d/99-resume.rules
fi
