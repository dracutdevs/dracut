#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

install() {
    # Optional uswsusp support
    for bin in /usr/sbin/resume /usr/lib/suspend/resume
    do
        [[ -x "${bin}" ]] && {
            inst "${bin}" /usr/sbin/resume
            [[ -f /etc/suspend.conf ]] && inst /etc/suspend.conf
            break 
        }
    done

    inst_hook cmdline 10 "$moddir/parse-resume.sh"
    inst_hook pre-udev 30 "$moddir/resume-genrules.sh"
    inst_hook mount 10 "$moddir/resume.sh"
}

