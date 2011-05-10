#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

# Creates the syslog udev rules to be triggered when interface becomes online.
type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh

detect_syslog() {
    syslogtype=""
    if [ -e /sbin/rsyslogd ]; then
        syslogtype="rsyslogd"
    elif [ -e /sbin/syslogd ]; then
        syslogtype="syslogd"
    elif [ /sbin/syslog-ng ]; then
        syslogtype="syslog-ng"
    else
        warn "Could not find any syslog binary although the syslogmodule is selected to be installed. Please check."
    fi
    echo "$syslogtype"
    [ -n "$syslogtype" ]
}

read syslogtype < /tmp/syslog.type
if [ -z "$syslogtype" ]; then
    syslogtype=$(detect_syslog)
    echo $syslogtype > /tmp/syslog.type
fi
if [ -e "/sbin/${syslogtype}-start" ]; then
    printf 'ACTION=="online", SUBSYSTEM=="net", RUN+="/sbin/initqueue --onetime /sbin/'${syslogtype}'-start $env{INTERFACE}"\n' > /etc/udev/rules.d/70-syslog.rules
else
    warn "syslog-genrules: Could not find binary to start syslog of type \"$syslogtype\". Syslog will not be started."
fi
