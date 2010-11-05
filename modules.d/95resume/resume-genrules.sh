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
    } >> /dev/.udev/rules.d/99-resume-link.rules

    {
        if [ -x /usr/sbin/resume ]; then
            printf "KERNEL==\"%s\", ACTION==\"add|change\", ENV{ID_FS_TYPE}==\"suspend|swsuspend|swsupend\", RUN+=\"/usr/sbin/resume %s '%s'\"\n" \
                ${resume#/dev/} "$a_splash" "$resume";
            printf "SYMLINK==\"%s\", ACTION==\"add|change\", ENV{ID_FS_TYPE}==\"suspend|swsuspend|swsupend\", RUN+=\"/usr/sbin/resume %s '%s'\"\n" \
                ${resume#/dev/} "$a_splash" "$resume";
        fi
        printf "KERNEL==\"%s\", ACTION==\"add|change\", ENV{ID_FS_TYPE}==\"suspend|swsuspend|swsupend\", RUN+=\"/bin/sh -c 'echo %%M:%%m > /sys/power/resume'\"\n" \
            ${resume#/dev/};
        printf "SYMLINK==\"%s\", ACTION==\"add|change\", ENV{ID_FS_TYPE}==\"suspend|swsuspend|swsupend\", RUN+=\"/bin/sh -c 'echo %%M:%%m > /sys/power/resume'\"\n" \
            ${resume#/dev/};
    } >> /etc/udev/rules.d/99-resume.rules

    printf '[ -e "%s" ] && { ln -s "%s" /dev/resume; rm "$job"; }\n' \
        "$resume" "$resume" >> /initqueue-settled/resume.sh

    echo '[ -e /dev/resume ]' > /initqueue-finished/resume.sh

    {
        printf '[ -e /dev/resume ] || '
        printf 'warn "resume device "%s" not found"\n' "$resume"
    } >> /emergency/00-resume.sh


elif ! getarg noresume; then
    {
        if [ -x /usr/sbin/resume ]; then
            printf "SUBSYSTEM==\"block\", ACTION==\"add|change\", ENV{ID_FS_TYPE}==\"suspend|swsuspend|swsupend\", RUN+=\"/usr/sbin/resume %s '\$tempnode'\"\n" "$a_splash"
        fi
        echo "SUBSYSTEM==\"block\", ACTION==\"add|change\", ENV{ID_FS_TYPE}==\"suspend|swsuspend|swsupend\"," \
            " RUN+=\"/bin/sh -c 'echo %M:%m > /sys/power/resume'\"";
    } >> /etc/udev/rules.d/99-resume.rules
fi
