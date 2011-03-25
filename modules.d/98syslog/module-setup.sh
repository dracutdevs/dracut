#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    # do not add this module by default
    return 255
}

depends() {
    return 0
}

install() {
    if type -P rsyslogd >/dev/null; then
        installs="rsyslogd"
        for i in {"$libdir","$usrlibdir"}/rsyslog/lmnet.so \
            {"$libdir","$usrlibdir"}/rsyslog/imklog.so \
            {"$libdir","$usrlibdir"}/rsyslog/imuxsock.so ; do
            [ -e "$i" ] && installs="$installs $i"
        done
    elif type -P syslogd >/dev/null; then
        installs="syslogd"
    elif type -P syslog-ng >/dev/null; then
        installs="syslog-ng"
    else
        derror "Could not find any syslog binary although the syslogmodule" \
            "is selected to be installed. Please check."
    fi
    if [ -n "$installs" ]; then
        dracut_install cat
        dracut_install $installs
        inst_hook cmdline  90 "$moddir/parse-syslog-opts.sh"
        inst_hook pre-udev 61 "$moddir/syslog-genrules.sh"
        inst_hook pre-pivot 99 "$moddir/syslog-cleanup.sh"
        inst_simple "$moddir/rsyslogd-start.sh" /sbin/rsyslogd-start
        inst_simple "$moddir/rsyslogd-stop.sh" /sbin/rsyslogd-stop
        mkdir -p ${initdir}/etc/templates
        inst_simple "${moddir}/rsyslog.conf" /etc/templates
    fi
}

