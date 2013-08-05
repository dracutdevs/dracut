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
    local _i
    local _installs
    if type -P rsyslogd >/dev/null; then
        _installs="rsyslogd"
        inst_libdir_file rsyslog/lmnet.so rsyslog/imklog.so rsyslog/imuxsock.so
    elif type -P syslogd >/dev/null; then
        _installs="syslogd"
    elif type -P syslog-ng >/dev/null; then
        _installs="syslog-ng"
    else
        derror "Could not find any syslog binary although the syslogmodule" \
            "is selected to be installed. Please check."
    fi
    if [ -n "$_installs" ]; then
        inst_multiple cat $_installs
        inst_hook cmdline  90 "$moddir/parse-syslog-opts.sh"
        inst_hook pre-udev 61 "$moddir/syslog-genrules.sh"
        inst_hook cleanup 99 "$moddir/syslog-cleanup.sh"
        inst_simple "$moddir/rsyslogd-start.sh" /sbin/rsyslogd-start
        inst_simple "$moddir/rsyslogd-stop.sh" /sbin/rsyslogd-stop
        mkdir -m 0755 -p ${initdir}/etc/templates
        inst_simple "${moddir}/rsyslog.conf" /etc/templates
    fi
    dracut_need_initqueue
}

